import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, describe, expect, it } from 'vitest';
import { bearer, buildApp, createCompanyWithIpos, createUser, fundWallet } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

describe('Phase 3: concurrency safety on balance-changing endpoints', () => {
  it('parallel subscribe requests (different keys) create exactly one subscription and one reservation', async () => {
    const rep = await createUser(ctx, 'company_rep');
    const inv = await createUser(ctx, 'investor');
    await fundWallet(ctx.db, inv.id, 1_000_000);
    const { ipos } = await createCompanyWithIpos(ctx.db, rep.id, ['open']);

    const results = await Promise.all(
      Array.from({ length: 6 }, () =>
        request(ctx.app)
          .post('/subscriptions')
          .set(bearer(inv.token))
          .set('Idempotency-Key', `k-${randomUUID()}`)
          .send({ ipo_id: ipos.open, quantity: 10 }),
      ),
    );

    const statuses = results.map((r) => r.status).sort();
    expect(statuses.filter((s) => s === 201)).toHaveLength(1);
    expect(statuses.filter((s) => s === 409)).toHaveLength(5);
    expect(statuses.every((s) => s !== 500)).toBe(true);

    const { rows } = await ctx.db.query<{ n: string }>(
      "SELECT count(*)::text AS n FROM subscriptions WHERE investor_id = $1 AND status = 'reserved'",
      [inv.id],
    );
    expect(rows[0]?.n).toBe('1');
    const w = await request(ctx.app).get('/wallets/me').set(bearer(inv.token));
    expect(w.body.data.reserved_minor).toBe(10 * 10000);
    expect(w.body.data.available_minor + w.body.data.reserved_minor).toBe(1_000_000);
  });

  it('a subscription racing with allocation is either allocated or rejected, never left reserved', async () => {
    const rep = await createUser(ctx, 'company_rep');
    const admin = await createUser(ctx, 'admin');
    const { ipos } = await createCompanyWithIpos(ctx.db, rep.id, ['open']);
    const investors = await Promise.all(Array.from({ length: 5 }, () => createUser(ctx, 'investor')));
    for (const i of investors) await fundWallet(ctx.db, i.id, 1_000_000);

    const subs = investors.map((i) =>
      request(ctx.app)
        .post('/subscriptions')
        .set(bearer(i.token))
        .set('Idempotency-Key', `k-${randomUUID()}`)
        .send({ ipo_id: ipos.open, quantity: 10 }),
    );
    const alloc = request(ctx.app).post(`/admin/ipos/${ipos.open}/allocate`).set(bearer(admin.token)).send({});
    const all = await Promise.all([...subs, alloc]);
    expect(all.every((r) => r.status < 500)).toBe(true);

    const { rows } = await ctx.db.query<{ n: string }>(
      "SELECT count(*)::text AS n FROM subscriptions WHERE ipo_id = $1 AND status = 'reserved'",
      [ipos.open],
    );
    expect(rows[0]?.n).toBe('0');
  });
});
