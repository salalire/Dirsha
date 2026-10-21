import { randomUUID } from 'node:crypto';
import jwt from 'jsonwebtoken';
import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { TOKEN_AUDIENCE, TOKEN_ISSUER } from '../src/http/auth.js';
import { bearer, buildApp, createCompanyWithIpos, createUser, TEST_JWT_SECRET, TEST_PASSWORD } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

const newEmail = (): string => `new-${randomUUID()}@example.test`;
const registerBody = (over: Record<string, unknown> = {}): Record<string, unknown> => ({
  email: newEmail(),
  password: TEST_PASSWORD,
  full_name: 'Abebe Kebede',
  role: 'investor',
  ...over,
});

describe('POST /auth/register', () => {
  it('creates an investor with an empty simulated wallet and never returns the hash', async () => {
    const res = await request(ctx.app).post('/auth/register').send(registerBody());
    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({
      role: 'investor',
      account_status: 'active',
      verification_status: 'unverified',
    });
    expect(JSON.stringify(res.body)).not.toMatch(/password|hash/i);

    const wallet = await ctx.db.query(
      'SELECT available_minor, reserved_minor FROM wallets WHERE user_id = $1',
      [res.body.data.id],
    );
    expect(wallet.rows).toEqual([{ available_minor: '0', reserved_minor: '0' }]);
  });

  it('stores a bcrypt hash, never the plaintext password', async () => {
    const body = registerBody();
    const res = await request(ctx.app).post('/auth/register').send(body);
    const { rows } = await ctx.db.query<{ password_hash: string }>(
      'SELECT password_hash FROM users WHERE id = $1',
      [res.body.data.id],
    );
    expect(rows[0]?.password_hash).toMatch(/^\$2[aby]\$/);
    expect(rows[0]?.password_hash).not.toContain(String(body.password));
  });

  it('does not create a wallet for company representatives or brokers', async () => {
    for (const role of ['company_rep', 'broker']) {
      const res = await request(ctx.app).post('/auth/register').send(registerBody({ role }));
      expect(res.status).toBe(201);
      const { rows } = await ctx.db.query('SELECT 1 FROM wallets WHERE user_id = $1', [res.body.data.id]);
      expect(rows).toHaveLength(0);
    }
  });

  it('rejects duplicate emails case-insensitively', async () => {
    const email = newEmail();
    expect((await request(ctx.app).post('/auth/register').send(registerBody({ email }))).status).toBe(201);
    const dup = await request(ctx.app)
      .post('/auth/register')
      .send(registerBody({ email: email.toUpperCase() }));
    expect(dup.status).toBe(409);
    expect(dup.body.error.code).toBe('EMAIL_ALREADY_REGISTERED');
  });

  it('cannot self-register as admin or set privileged / financial fields', async () => {
    const asAdmin = await request(ctx.app).post('/auth/register').send(registerBody({ role: 'admin' }));
    expect(asAdmin.status).toBe(400);
    expect(asAdmin.body.error.code).toBe('VALIDATION_ERROR');

    for (const extra of [
      { account_status: 'active' },
      { verification_status: 'verified' },
      { balance: 1_000_000 },
      { available_minor: 1_000_000 },
    ]) {
      const res = await request(ctx.app).post('/auth/register').send(registerBody(extra));
      expect(res.status, JSON.stringify(extra)).toBe(400);
    }
  });

  it('validates email, password length and name', async () => {
    const cases: Record<string, unknown>[] = [
      { email: 'not-an-email' },
      { password: 'short' },
      { password: 'x'.repeat(73) },
      { full_name: '   ' },
      { phone: 'abc' },
    ];
    for (const over of cases) {
      const res = await request(ctx.app).post('/auth/register').send(registerBody(over));
      expect(res.status, JSON.stringify(over)).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    }
  });

  it('never echoes the submitted password in validation errors', async () => {
    const res = await request(ctx.app)
      .post('/auth/register')
      .send(registerBody({ password: 'tiny', email: 'bad' }));
    expect(JSON.stringify(res.body)).not.toContain('tiny');
  });

  it('writes an audit event without secrets', async () => {
    const res = await request(ctx.app).post('/auth/register').send(registerBody());
    const { rows } = await ctx.db.query(
      "SELECT action, outcome, metadata FROM audit_events WHERE action = 'auth.register' AND target_id = $1",
      [res.body.data.id],
    );
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({ outcome: 'success', metadata: {} });
  });
});

describe('POST /auth/login', () => {
  it('returns a bearer token and the user', async () => {
    const email = newEmail();
    await request(ctx.app).post('/auth/register').send(registerBody({ email }));
    const res = await request(ctx.app).post('/auth/login').send({ email, password: TEST_PASSWORD });
    expect(res.status).toBe(200);
    expect(res.body.data.token_type).toBe('Bearer');
    expect(res.body.data.expires_in).toBe(900);
    expect(res.body.data.user.email).toBe(email);
    expect(JSON.stringify(res.body)).not.toMatch(/password|hash/i);

    const me = await request(ctx.app).get('/users/me').set(bearer(res.body.data.access_token));
    expect(me.status).toBe(200);
    expect(me.body.data.email).toBe(email);
  });

  it('is case-insensitive on email', async () => {
    const email = newEmail();
    await request(ctx.app).post('/auth/register').send(registerBody({ email }));
    const res = await request(ctx.app)
      .post('/auth/login')
      .send({ email: email.toUpperCase(), password: TEST_PASSWORD });
    expect(res.status).toBe(200);
  });

  it('gives the same error for a wrong password and an unknown email', async () => {
    const email = newEmail();
    await request(ctx.app).post('/auth/register').send(registerBody({ email }));
    const wrong = await request(ctx.app).post('/auth/login').send({ email, password: 'wrong-password-1' });
    const unknown = await request(ctx.app)
      .post('/auth/login')
      .send({ email: newEmail(), password: 'wrong-password-1' });
    expect(wrong.status).toBe(401);
    expect(unknown.status).toBe(401);
    expect(wrong.body.error.code).toBe('INVALID_CREDENTIALS');
    expect(unknown.body.error.code).toBe('INVALID_CREDENTIALS');
    expect(wrong.body.error.message).toBe(unknown.body.error.message);
  });

  it('records failed sign-ins in the audit log without storing the password or email', async () => {
    const res = await request(ctx.app)
      .post('/auth/login')
      .send({ email: newEmail(), password: 'super-secret-guess-9' });
    const requestId = res.headers['x-request-id'];
    const { rows } = await ctx.db.query(
      'SELECT action, outcome, metadata, actor_user_id FROM audit_events WHERE request_id = $1',
      [requestId],
    );
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({ action: 'auth.login', outcome: 'failure', actor_user_id: null });
    expect(JSON.stringify(rows[0])).not.toContain('super-secret-guess-9');
    expect(JSON.stringify(rows[0])).not.toContain('example.test');
  });

  it('rejects suspended accounts even with the right password', async () => {
    const user = await createUser(ctx, 'investor', { suspended: true });
    const res = await request(ctx.app).post('/auth/login').send({ email: user.email, password: TEST_PASSWORD });
    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('ACCOUNT_SUSPENDED');
  });

  it('rate-limits repeated attempts', async () => {
    const limited = buildApp({ AUTH_RATE_LIMIT_MAX: '3' });
    try {
      const statuses: number[] = [];
      for (let i = 0; i < 5; i++) {
        const res = await request(limited.app)
          .post('/auth/login')
          .send({ email: 'someone@example.test', password: 'wrong-password-1' });
        statuses.push(res.status);
        if (res.status === 429) expect(res.body.error.code).toBe('RATE_LIMITED');
      }
      expect(statuses).toEqual([401, 401, 401, 429, 429]);
    } finally {
      await limited.close();
    }
  });
});

describe('authentication on protected routes', () => {
  it('rejects requests with no, malformed or non-bearer credentials', async () => {
    for (const header of [undefined, 'Bearer', 'Basic abc', 'Bearer not.a.jwt', 'Bearer ']) {
      const req = request(ctx.app).get('/users/me');
      if (header !== undefined) req.set('Authorization', header);
      const res = await req;
      expect(res.status, String(header)).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHENTICATED');
    }
  });

  it('rejects a token signed with another secret', async () => {
    const user = await createUser(ctx, 'investor');
    const forged = jwt.sign({}, 'a-completely-different-secret-value-123456', {
      subject: user.id,
      issuer: TOKEN_ISSUER,
      audience: TOKEN_AUDIENCE,
    });
    expect((await request(ctx.app).get('/users/me').set(bearer(forged))).status).toBe(401);
  });

  it('rejects expired tokens, wrong audience, and alg=none', async () => {
    const user = await createUser(ctx, 'investor');
    const expired = jwt.sign({}, TEST_JWT_SECRET, {
      subject: user.id,
      issuer: TOKEN_ISSUER,
      audience: TOKEN_AUDIENCE,
      expiresIn: -10,
    });
    const wrongAudience = jwt.sign({}, TEST_JWT_SECRET, {
      subject: user.id,
      issuer: TOKEN_ISSUER,
      audience: 'someone-else',
    });
    const none = `${Buffer.from('{"alg":"none","typ":"JWT"}').toString('base64url')}.${Buffer.from(
      JSON.stringify({ sub: user.id, iss: TOKEN_ISSUER, aud: TOKEN_AUDIENCE }),
    ).toString('base64url')}.`;
    for (const token of [expired, wrongAudience, none]) {
      expect((await request(ctx.app).get('/users/me').set(bearer(token))).status).toBe(401);
    }
  });

  it('takes the role from the database, never from token claims', async () => {
    const rep = await createUser(ctx, 'company_rep');
    // A token that *claims* to be admin/investor but belongs to a company rep.
    const lying = jwt.sign({ role: 'investor' }, TEST_JWT_SECRET, {
      subject: rep.id,
      issuer: TOKEN_ISSUER,
      audience: TOKEN_AUDIENCE,
    });
    const res = await request(ctx.app).get('/wallets/me').set(bearer(lying));
    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('FORBIDDEN');
  });

  it('takes effect immediately when an account is suspended', async () => {
    const user = await createUser(ctx, 'investor');
    expect((await request(ctx.app).get('/users/me').set(bearer(user.token))).status).toBe(200);
    await ctx.db.query("UPDATE users SET account_status = 'suspended' WHERE id = $1", [user.id]);
    const res = await request(ctx.app).get('/users/me').set(bearer(user.token));
    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('ACCOUNT_SUSPENDED');
  });

  it('protects every non-public route', async () => {
    const owner = await createUser(ctx, 'company_rep');
    const { ipos } = await createCompanyWithIpos(ctx.db, owner.id, ['open']);
    const protectedRoutes = [
      '/users/me',
      '/ipos',
      `/ipos/${ipos.open}`,
      '/wallets/me',
      '/wallets/me/transactions',
    ];
    for (const path of protectedRoutes) {
      expect((await request(ctx.app).get(path)).status, path).toBe(401);
    }
    expect((await request(ctx.app).post('/dev/test-funds').send({ amount_minor: 100 })).status).toBe(401);
  });
});
