import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { MAX_TEST_FUND_MINOR } from '../src/modules/wallet/wallet.service.js';
import { bearer, buildApp, createUser, fundWallet, walletIdOf } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

const key = (): string => `key-${randomUUID()}`;
/** `idemKey`: a string to send, or `null` to omit the header entirely. */
const credit = (token: string, body: unknown, idemKey: string | null = key()) => {
  const req = request(ctx.app).post('/dev/test-funds').set(bearer(token));
  if (idemKey !== null) req.set('Idempotency-Key', idemKey);
  return req.send(body as object);
};

describe('GET /wallets/me', () => {
  it('returns a zero, clearly simulated wallet for a new investor', async () => {
    const u = await createUser(ctx, 'investor');
    const res = await request(ctx.app).get('/wallets/me').set(bearer(u.token));
    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({
      currency: 'ETB',
      simulated: true,
      available_minor: 0,
      reserved_minor: 0,
      total_minor: 0,
    });
  });

  it('reflects ledger-backed funds', async () => {
    const u = await createUser(ctx, 'investor');
    await fundWallet(ctx.db, u.id, 1_000_000);
    const res = await request(ctx.app).get('/wallets/me').set(bearer(u.token));
    expect(res.body.data).toMatchObject({ available_minor: 1_000_000, total_minor: 1_000_000 });
  });

  it("never exposes another user's wallet (no id parameter exists)", async () => {
    const a = await createUser(ctx, 'investor');
    const b = await createUser(ctx, 'investor');
    await fundWallet(ctx.db, b.id, 500_000);
    const aWallet = await request(ctx.app).get('/wallets/me').set(bearer(a.token));
    expect(aWallet.body.data.available_minor).toBe(0);
    const bWalletId = await walletIdOf(ctx.db, b.id);
    for (const path of [`/wallets/${bWalletId}`, `/wallets/${b.id}`, `/wallets/${bWalletId}/transactions`]) {
      const res = await request(ctx.app).get(path).set(bearer(a.token));
      // Falls through to the 403 role gate or a 404 - never a 200 with B's data.
      expect([403, 404]).toContain(res.status);
      expect(JSON.stringify(res.body)).not.toContain('500000');
    }
  });

  it('is investor-only: companies, brokers and admins get 403', async () => {
    for (const role of ['company_rep', 'broker', 'admin'] as const) {
      const u = await createUser(ctx, role);
      const res = await request(ctx.app).get('/wallets/me').set(bearer(u.token));
      expect(res.status, role).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    }
  });

  it('exposes no way to write a balance', async () => {
    const u = await createUser(ctx, 'investor');
    for (const [method, path] of [
      ['patch', '/wallets/me'],
      ['put', '/wallets/me'],
      ['post', '/wallets/me'],
      ['post', '/wallets/me/transactions'],
      ['delete', '/wallets/me/transactions'],
    ] as const) {
      const res = await request(ctx.app)[method](path).set(bearer(u.token)).send({ available_minor: 99_999_999 });
      expect(res.status, `${method} ${path}`).toBe(404);
    }
    const wallet = await request(ctx.app).get('/wallets/me').set(bearer(u.token));
    expect(wallet.body.data.available_minor).toBe(0);
  });
});

describe('GET /wallets/me/transactions', () => {
  it('lists the ledger newest-first with pagination and full detail', async () => {
    const u = await createUser(ctx, 'investor');
    for (const amount of [100, 200, 300]) {
      await credit(u.token, { amount_minor: amount });
    }
    const page1 = await request(ctx.app).get('/wallets/me/transactions?page_size=2').set(bearer(u.token));
    expect(page1.status).toBe(200);
    expect(page1.body.pagination).toEqual({ page: 1, page_size: 2, total: 3 });
    expect(page1.body.data.map((t: { available_delta_minor: number }) => t.available_delta_minor)).toEqual([300, 200]);
    expect(page1.body.data[0]).toMatchObject({
      type: 'test_fund_credit',
      status: 'posted',
      available_after_minor: 600,
      reserved_after_minor: 0,
    });
    expect(typeof page1.body.data[0].id).toBe('string');
    expect(typeof page1.body.data[0].created_at).toBe('string');

    const page2 = await request(ctx.app).get('/wallets/me/transactions?page=2&page_size=2').set(bearer(u.token));
    expect(page2.body.data.map((t: { available_delta_minor: number }) => t.available_delta_minor)).toEqual([100]);
  });

  it("only returns the caller's own entries", async () => {
    const a = await createUser(ctx, 'investor');
    const b = await createUser(ctx, 'investor');
    await credit(b.token, { amount_minor: 777 });
    const res = await request(ctx.app).get('/wallets/me/transactions').set(bearer(a.token));
    expect(res.body.data).toEqual([]);
    expect(res.body.pagination.total).toBe(0);
  });
});

describe('POST /dev/test-funds (simulated money, dev/test only)', () => {
  it('credits the caller through the ledger and audits it', async () => {
    const u = await createUser(ctx, 'investor');
    const idem = key();
    const res = await credit(u.token, { amount_minor: 1_000_000 }, idem);
    expect(res.status).toBe(201);
    expect(res.headers['idempotent-replay']).toBe('false');
    expect(res.body.data.wallet).toMatchObject({ available_minor: 1_000_000, simulated: true });
    expect(res.body.data.transaction).toMatchObject({
      type: 'test_fund_credit',
      available_delta_minor: 1_000_000,
      available_after_minor: 1_000_000,
    });

    const audit = await ctx.db.query(
      "SELECT outcome FROM audit_events WHERE action = 'wallet.test_fund_credit' AND actor_user_id = $1",
      [u.id],
    );
    expect(audit.rows).toEqual([{ outcome: 'success' }]);
  });

  it('is idempotent: a retry with the same key changes nothing and returns the original', async () => {
    const u = await createUser(ctx, 'investor');
    const idem = key();
    const first = await credit(u.token, { amount_minor: 5_000 }, idem);
    const retry = await credit(u.token, { amount_minor: 5_000 }, idem);
    expect(retry.status).toBe(200);
    expect(retry.headers['idempotent-replay']).toBe('true');
    expect(retry.body.data.transaction.id).toBe(first.body.data.transaction.id);
    expect(retry.body.data.wallet.available_minor).toBe(5_000);

    const count = await ctx.db.query('SELECT count(*)::int AS n FROM ledger_entries WHERE wallet_id = $1', [
      await walletIdOf(ctx.db, u.id),
    ]);
    expect(count.rows[0]).toEqual({ n: 1 });
    const audit = await ctx.db.query(
      "SELECT count(*)::int AS n FROM audit_events WHERE action = 'wallet.test_fund_credit' AND actor_user_id = $1",
      [u.id],
    );
    expect(audit.rows[0]).toEqual({ n: 1 });
  });

  it('rejects the same key reused with a different amount', async () => {
    const u = await createUser(ctx, 'investor');
    const idem = key();
    await credit(u.token, { amount_minor: 5_000 }, idem);
    const res = await credit(u.token, { amount_minor: 9_000 }, idem);
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('IDEMPOTENCY_KEY_REUSED');
    const wallet = await request(ctx.app).get('/wallets/me').set(bearer(u.token));
    expect(wallet.body.data.available_minor).toBe(5_000);
  });

  it('requires a well-formed Idempotency-Key', async () => {
    const u = await createUser(ctx, 'investor');
    for (const bad of [null, 'short', 'has spaces in it!!', 'x'.repeat(129)]) {
      const res = await credit(u.token, { amount_minor: 100 }, bad);
      expect(res.status, String(bad)).toBe(400);
    }
  });

  it('validates the amount: integer, positive, capped per call', async () => {
    const u = await createUser(ctx, 'investor');
    for (const amount of [0, -5, 10.5, '100', null, MAX_TEST_FUND_MINOR + 1, Number.MAX_SAFE_INTEGER]) {
      const res = await credit(u.token, { amount_minor: amount });
      expect(res.status, String(amount)).toBe(400);
    }
    expect((await credit(u.token, { amount_minor: MAX_TEST_FUND_MINOR })).status).toBe(201);
  });

  it('cannot target another wallet or set balances directly', async () => {
    const a = await createUser(ctx, 'investor');
    const b = await createUser(ctx, 'investor');
    const bWallet = await walletIdOf(ctx.db, b.id);
    for (const extra of [
      { wallet_id: bWallet },
      { user_id: b.id },
      { available_minor: 1_000_000 },
      { balance: 1_000_000 },
    ]) {
      const res = await credit(a.token, { amount_minor: 100, ...extra });
      expect(res.status, JSON.stringify(extra)).toBe(400);
    }
    const bAfter = await request(ctx.app).get('/wallets/me').set(bearer(b.token));
    expect(bAfter.body.data.available_minor).toBe(0);
  });

  it('is restricted to investors', async () => {
    for (const role of ['company_rep', 'broker', 'admin'] as const) {
      const u = await createUser(ctx, role);
      expect((await credit(u.token, { amount_minor: 100 })).status, role).toBe(403);
    }
  });

  it('is not mounted at all when ENABLE_TEST_FUNDS is off', async () => {
    const off = buildApp({ ENABLE_TEST_FUNDS: 'false' });
    try {
      const u = await createUser(off, 'investor');
      const res = await request(off.app)
        .post('/dev/test-funds')
        .set(bearer(u.token))
        .set('Idempotency-Key', key())
        .send({ amount_minor: 100 });
      expect(res.status).toBe(404);
      const wallet = await request(off.app).get('/wallets/me').set(bearer(u.token));
      expect(wallet.body.data.available_minor).toBe(0);
    } finally {
      await off.close();
    }
  });
});

describe('wallet / ledger reconciliation', () => {
  it('every wallet balance equals the sum of its ledger entries', async () => {
    const u = await createUser(ctx, 'investor');
    await credit(u.token, { amount_minor: 1234 });
    await credit(u.token, { amount_minor: 4321 });
    const { rows } = await ctx.db.query<{ ok: boolean }>(
      'SELECT ok FROM wallet_reconciliation WHERE wallet_id = $1',
      [await walletIdOf(ctx.db, u.id)],
    );
    expect(rows).toEqual([{ ok: true }]);
    const broken = await ctx.db.query('SELECT count(*)::int AS n FROM wallet_reconciliation WHERE NOT ok');
    expect(broken.rows[0]).toEqual({ n: 0 });
  });
});
