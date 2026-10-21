import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { createAdminAccount } from '../src/modules/users/admin-provision.js';
import { bearer, buildApp } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

const base = (): { email: string; password: string; fullName: string; bcryptCost: number } => ({
  email: `admin-${randomUUID()}@example.test`,
  password: 'a-long-admin-passphrase',
  fullName: 'Provisioned Admin',
  bcryptCost: 4,
});

describe('admin provisioning (out-of-band; public registration can never create admins)', () => {
  it('creates an admin who can sign in, and audits it without the password', async () => {
    const input = base();
    const admin = await createAdminAccount(ctx.db, input);

    const login = await request(ctx.app)
      .post('/auth/login')
      .send({ email: input.email, password: input.password });
    expect(login.status).toBe(200);
    expect(login.body.data.user.role).toBe('admin');

    const me = await request(ctx.app).get('/users/me').set(bearer(login.body.data.access_token));
    expect(me.body.data.role).toBe('admin');

    const audit = await ctx.db.query(
      "SELECT outcome, metadata FROM audit_events WHERE action = 'admin.provisioned' AND target_id = $1",
      [admin.id],
    );
    expect(audit.rows).toHaveLength(1);
    expect(JSON.stringify(audit.rows[0])).not.toContain(input.password);
  });

  it('rejects weak passwords, bad emails and duplicates', async () => {
    await expect(createAdminAccount(ctx.db, { ...base(), password: 'short-pass' })).rejects.toMatchObject({
      code: 'VALIDATION_ERROR',
    });
    await expect(createAdminAccount(ctx.db, { ...base(), email: 'nope' })).rejects.toMatchObject({
      code: 'VALIDATION_ERROR',
    });
    const input = base();
    await createAdminAccount(ctx.db, input);
    await expect(createAdminAccount(ctx.db, input)).rejects.toMatchObject({
      code: 'EMAIL_ALREADY_REGISTERED',
    });
  });
});
