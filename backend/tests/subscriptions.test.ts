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

let investor: TestUser;
let poorInvestor: TestUser;
let otherInvestor: TestUser;
let suspendedInvestor: TestUser;
let admin: TestUser;
let broker: TestUser;
let companyRep: TestUser;
let ipos: Record<string, string>;

beforeAll(async () => {
  [
    investor,
    poorInvestor,
    otherInvestor,
    suspendedInvestor,
    admin,
    broker,
    companyRep,
  ] = await Promise.all([
    createUser(ctx, 'investor'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'investor', { suspended: true }),
    createUser(ctx, 'admin'),
    createUser(ctx, 'broker'),
    createUser(ctx, 'company_rep'),
  ]);

  // Give investor 10,000.00 ETB (1,000,000 santim)
  await fundWallet(ctx.db, investor.id, 1_000_000);
  // poorInvestor has 0 funds
  // otherInvestor gets 5,000.00 ETB (500,000 santim)
  await fundWallet(ctx.db, otherInvestor.id, 500_000);

  // Create IPOs: open (100.00 ETB / share, min 10, max 500), draft, listed
  const res = await createCompanyWithIpos(ctx.db, companyRep.id, ['open', 'draft', 'listed']);
  ipos = res.ipos;

  await ctx.db.query(
    `UPDATE ipos
     SET min_shares_per_subscription = 10, max_shares_per_subscription = 500
     WHERE id = $1`,
    [ipos.open],
  );
});

describe('POST /subscriptions (FR-SUB-01..04, FR-LED-03, NFR-FIN-02/03)', () => {
  it('rejects unauthenticated requests with 401', async () => {
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set('Idempotency-Key', `idem-${randomUUID()}`)
      .send({ ipo_id: ipos.open, quantity: 20 });
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHENTICATED');
  });

  it('rejects non-investors with 403', async () => {
    for (const u of [broker, admin, companyRep]) {
      const res = await request(ctx.app)
        .post('/subscriptions')
        .set(bearer(u.token))
        .set('Idempotency-Key', `idem-${randomUUID()}`)
        .send({ ipo_id: ipos.open, quantity: 20 });
      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    }
  });

  it('rejects suspended investors with 403', async () => {
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(suspendedInvestor.token))
      .set('Idempotency-Key', `idem-${randomUUID()}`)
      .send({ ipo_id: ipos.open, quantity: 20 });
    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('ACCOUNT_SUSPENDED');
  });

  it('rejects requests without an Idempotency-Key header', async () => {
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .send({ ipo_id: ipos.open, quantity: 20 });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('rejects non-existent IPO with 404', async () => {
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `idem-${randomUUID()}`)
      .send({ ipo_id: randomUUID(), quantity: 20 });
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('rejects an IPO that is not open with 422 IPO_NOT_OPEN', async () => {
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `idem-${randomUUID()}`)
      .send({ ipo_id: ipos.draft, quantity: 20 });
    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('IPO_NOT_OPEN');
  });

  it('rejects quantity outside IPO limits with 400', async () => {
    // IPO min is 10, max is 500
    const under = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `idem-${randomUUID()}`)
      .send({ ipo_id: ipos.open, quantity: 5 });
    expect(under.status).toBe(400);
    expect(under.body.error.code).toBe('VALIDATION_ERROR');

    const over = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `idem-${randomUUID()}`)
      .send({ ipo_id: ipos.open, quantity: 501 });
    expect(over.status).toBe(400);
    expect(over.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('rejects with 422 INSUFFICIENT_FUNDS when available balance is too low', async () => {
    // poorInvestor has 0 funds
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(poorInvestor.token))
      .set('Idempotency-Key', `idem-${randomUUID()}`)
      .send({ ipo_id: ipos.open, quantity: 20 });
    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('INSUFFICIENT_FUNDS');
  });

  let createdSubId: string;
  const testIdemKey = `idem-${randomUUID()}`;

  it('successfully creates a subscription and reserves funds atomically (201)', async () => {
    // 30 shares @ 100.00 ETB (10000 minor) = 300,000 minor (3,000.00 ETB)
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', testIdemKey)
      .send({ ipo_id: ipos.open, quantity: 30 });

    expect(res.status).toBe(201);
    expect(res.header['idempotent-replay']).toBe('false');
    expect(res.body.data).toMatchObject({
      ipo_id: ipos.open,
      investor_id: investor.id,
      quantity: 30,
      amount_minor: 300000,
      allocated_quantity: 0,
      status: 'reserved',
    });
    expect(res.body.data.id).toBeDefined();
    expect(res.body.data.reservation_ledger_entry_id).toBeDefined();
    createdSubId = res.body.data.id;

    // Check investor's wallet balance: available decreased by 300,000, reserved increased by 300,000
    const walletRes = await request(ctx.app)
      .get('/wallets/me')
      .set(bearer(investor.token));
    expect(walletRes.status).toBe(200);
    expect(walletRes.body.data.available_minor).toBe(700000);
    expect(walletRes.body.data.reserved_minor).toBe(300000);
    expect(walletRes.body.data.total_minor).toBe(1000000);

    // Check transaction history has the reservation
    const txRes = await request(ctx.app)
      .get('/wallets/me/transactions')
      .set(bearer(investor.token));
    expect(txRes.status).toBe(200);
    expect(txRes.body.data[0]).toMatchObject({
      type: 'subscription_reserve',
      available_delta_minor: -300000,
      reserved_delta_minor: 300000,
      reference_type: 'subscription',
      reference_id: createdSubId,
    });
  });

  it('replaying the identical request returns 200 with Idempotent-Replay: true and does not re-deduct funds', async () => {
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', testIdemKey)
      .send({ ipo_id: ipos.open, quantity: 30 });

    expect(res.status).toBe(200);
    expect(res.header['idempotent-replay']).toBe('true');
    expect(res.body.data.id).toBe(createdSubId);

    // Wallet balance must remain unchanged (700,000 available / 300,000 reserved)
    const walletRes = await request(ctx.app)
      .get('/wallets/me')
      .set(bearer(investor.token));
    expect(walletRes.body.data.available_minor).toBe(700000);
    expect(walletRes.body.data.reserved_minor).toBe(300000);
  });

  it('reusing the idempotency key with a different body returns 409 IDEMPOTENCY_KEY_REUSED', async () => {
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', testIdemKey)
      .send({ ipo_id: ipos.open, quantity: 50 }); // different quantity!

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('IDEMPOTENCY_KEY_REUSED');
  });

  it('rejects a second active subscription for the same IPO with 409 CONFLICT (Rule B4)', async () => {
    const res = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `new-key-${randomUUID()}`)
      .send({ ipo_id: ipos.open, quantity: 20 });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CONFLICT');
  });
});

describe('GET /subscriptions and GET /subscriptions/:id (FR-SUB-04, FR-SUB-07)', () => {
  it('investors only see their own subscriptions', async () => {
    // otherInvestor subscribes to ipos.open
    const otherKey = `other-${randomUUID()}`;
    await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(otherInvestor.token))
      .set('Idempotency-Key', otherKey)
      .send({ ipo_id: ipos.open, quantity: 15 });

    // investor queries /subscriptions
    const res = await request(ctx.app)
      .get('/subscriptions')
      .set(bearer(investor.token));
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(1);
    expect(res.body.data[0].investor_id).toBe(investor.id);
  });

  it('admins can see all subscriptions across investors', async () => {
    const res = await request(ctx.app)
      .get('/subscriptions')
      .set(bearer(admin.token));
    expect(res.status).toBe(200);
    // At least investor and otherInvestor
    expect(res.body.data.length).toBeGreaterThanOrEqual(2);
  });

  it('investors can get their own subscription by id', async () => {
    const listRes = await request(ctx.app)
      .get('/subscriptions')
      .set(bearer(investor.token));
    const subId = listRes.body.data[0].id;

    const res = await request(ctx.app)
      .get(`/subscriptions/${subId}`)
      .set(bearer(investor.token));
    expect(res.status).toBe(200);
    expect(res.body.data.id).toBe(subId);
  });

  it('an investor receives 404 when requesting another investor subscription by id', async () => {
    const listRes = await request(ctx.app)
      .get('/subscriptions')
      .set(bearer(otherInvestor.token));
    const otherSubId = listRes.body.data[0].id;

    // investor tries to fetch otherInvestor's sub
    const res = await request(ctx.app)
      .get(`/subscriptions/${otherSubId}`)
      .set(bearer(investor.token));
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('admins can get any subscription by id', async () => {
    const listRes = await request(ctx.app)
      .get('/subscriptions')
      .set(bearer(otherInvestor.token));
    const otherSubId = listRes.body.data[0].id;

    const res = await request(ctx.app)
      .get(`/subscriptions/${otherSubId}`)
      .set(bearer(admin.token));
    expect(res.status).toBe(200);
    expect(res.body.data.id).toBe(otherSubId);
  });
});
