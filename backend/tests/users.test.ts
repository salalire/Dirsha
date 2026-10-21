import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { bearer, buildApp, createUser } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

describe('GET/PATCH /users/me', () => {
  it('returns only the caller, with role and statuses as separate fields', async () => {
    const a = await createUser(ctx, 'investor');
    const b = await createUser(ctx, 'investor');
    const res = await request(ctx.app).get('/users/me').set(bearer(a.token));
    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({
      id: a.id,
      role: 'investor',
      account_status: 'active',
      verification_status: 'unverified',
    });
    expect(res.body.data.id).not.toBe(b.id);
    expect(JSON.stringify(res.body)).not.toMatch(/password|hash/i);
  });

  it('updates permitted profile fields and can clear the phone number', async () => {
    const u = await createUser(ctx, 'investor');
    const res = await request(ctx.app)
      .patch('/users/me')
      .set(bearer(u.token))
      .send({ full_name: 'Updated Name', phone: '+251 911 000 000' });
    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({ full_name: 'Updated Name', phone: '+251 911 000 000' });

    const cleared = await request(ctx.app).patch('/users/me').set(bearer(u.token)).send({ phone: null });
    expect(cleared.body.data.phone).toBeNull();
    expect(cleared.body.data.full_name).toBe('Updated Name');
  });

  it('cannot change role, account status, verification status or email', async () => {
    const u = await createUser(ctx, 'investor');
    for (const body of [
      { role: 'admin' },
      { account_status: 'active' },
      { verification_status: 'verified' },
      { email: 'other@example.test' },
    ]) {
      const res = await request(ctx.app).patch('/users/me').set(bearer(u.token)).send(body);
      expect(res.status, JSON.stringify(body)).toBe(400);
    }
    const { rows } = await ctx.db.query<{ role: string; verification_status: string }>(
      'SELECT role, verification_status FROM users WHERE id = $1',
      [u.id],
    );
    expect(rows[0]).toEqual({ role: 'investor', verification_status: 'unverified' });
  });

  it('rejects an empty update', async () => {
    const u = await createUser(ctx, 'investor');
    expect((await request(ctx.app).patch('/users/me').set(bearer(u.token)).send({})).status).toBe(400);
  });
});
