import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  buildApp,
  createCompanyWithIpos,
  createUser,
  fundWallet,
  type TestUser,
} from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

let investor1: TestUser;
let investor2: TestUser;
let admin: TestUser;
let companyRep: TestUser;
let ipos: Record<string, string>;

beforeAll(async () => {
  [investor1, investor2, admin, companyRep] = await Promise.all([
    createUser(ctx, 'investor'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'admin'),
    createUser(ctx, 'company_rep'),
  ]);

  await fundWallet(ctx.db, investor1.id, 1_000_000);
  await fundWallet(ctx.db, investor2.id, 1_000_000);

  const res = await createCompanyWithIpos(ctx.db, companyRep.id, ['open']);
  ipos = res.ipos;

  await ctx.db.query(
    `UPDATE ipos
     SET price_per_share_minor = 5000,
         total_shares = 1000,
         min_shares_per_subscription = 5,
         max_shares_per_subscription = 500
     WHERE id = $1`,
    [ipos.open],
  );
});

describe('GET /portfolio (FR-PORT-01..04)', () => {
  it('rejects unauthenticated request with 401', async () => {
    const res = await request(ctx.app).get('/portfolio');
    expect(res.status).toBe(401);
  });

  it('rejects non-investor roles with 403', async () => {
    const res = await request(ctx.app)
      .get('/portfolio')
      .set(bearer(admin.token));
    expect(res.status).toBe(403);
  });

  it('returns empty portfolio when investor has no holdings', async () => {
    const res = await request(ctx.app)
      .get('/portfolio')
      .set(bearer(investor1.token));

    expect(res.status).toBe(200);
    expect(res.body.data).toBeDefined();
    expect(res.body.data.summary.total_positions).toBe(0);
    expect(res.body.data.summary.total_shares).toBe(0);
    expect(res.body.data.summary.total_valuation_minor).toBe(0);
    expect(res.body.data.holdings).toEqual([]);
  });

  it('does not treat pending reserved subscriptions as holdings', async () => {
    // Investor 1 subscribes for 20 shares (100,000 santim)
    const subRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor1.token))
      .set('Idempotency-Key', randomUUID())
      .send({ ipo_id: ipos.open, quantity: 20 });
    expect(subRes.status).toBe(201);

    // Check portfolio: must still be 0 holdings
    const portRes = await request(ctx.app)
      .get('/portfolio')
      .set(bearer(investor1.token));

    expect(portRes.status).toBe(200);
    expect(portRes.body.data.summary.total_positions).toBe(0);
    expect(portRes.body.data.summary.total_shares).toBe(0);
    expect(portRes.body.data.holdings).toEqual([]);
  });

  it('reflects allocated shares in portfolio after IPO allocation', async () => {
    // Admin allocates the IPO
    const allocRes = await request(ctx.app)
      .post(`/admin/ipos/${ipos.open}/allocate`)
      .set(bearer(admin.token))
      .send();
    expect(allocRes.status).toBe(200);

    // Investor 1 checks portfolio
    const portRes = await request(ctx.app)
      .get('/portfolio')
      .set(bearer(investor1.token));

    expect(portRes.status).toBe(200);
    const data = portRes.body.data;
    expect(data.summary.total_positions).toBe(1);
    expect(data.summary.total_shares).toBe(20);
    expect(data.summary.total_valuation_minor).toBe(20 * 5000); // 100,000 santim
    expect(data.summary.valuation_source).toBe('ipo_offering_price');

    expect(data.holdings.length).toBe(1);
    const h = data.holdings[0];
    expect(h.ipo_id).toBe(ipos.open);
    expect(h.allocated_quantity).toBe(20);
    expect(h.price_per_share_minor).toBe(5000);
    expect(h.total_value_minor).toBe(100000);
    expect(h.currency).toBe('ETB');
    expect(h.company_name).toBeDefined();
    expect(h.title).toBeDefined();
  });

  it('ensures investor isolation (FR-PORT-04)', async () => {
    // Investor 2 did not subscribe, so portfolio must be empty
    const portRes = await request(ctx.app)
      .get('/portfolio')
      .set(bearer(investor2.token));

    expect(portRes.status).toBe(200);
    expect(portRes.body.data.summary.total_positions).toBe(0);
    expect(portRes.body.data.holdings).toEqual([]);
  });
});
