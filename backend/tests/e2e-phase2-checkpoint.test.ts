import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  buildApp,
  createCompanyWithIpos,
  createUser,
  fundWallet,
  TEST_PASSWORD,
  type TestCtx,
} from './helpers.js';

describe('Phase 2 Exit Checkpoint Acceptance Test (T-2.10)', () => {
  let ctx: TestCtx;
  let adminToken: string;
  let companyOwnerId: string;
  let ipoId: string;

  beforeAll(async () => {
    ctx = buildApp();
    const admin = await createUser(ctx, 'admin');
    adminToken = admin.token;

    const companyRep = await createUser(ctx, 'company_rep');
    companyOwnerId = companyRep.id;

    // Create company and open IPO (100 ETB / share = 10,000 santim)
    const { ipos } = await createCompanyWithIpos(ctx.db, companyOwnerId, ['open']);
    ipoId = ipos.open!;
  });

  afterAll(async () => {
    await ctx.close();
  });

  it('executes full primary market lifecycle: funding -> reserve -> idempotent retry -> 422 check -> admin close & allocate', async () => {
    // 1. Create and authenticate test investor with 10,000 ETB (1,000,000 santim)
    const investor = await createUser(ctx, 'investor');
    await fundWallet(ctx.db, investor.id, 1_000_000); // 10,000 ETB

    const loginRes = await request(ctx.app)
      .post('/auth/login')
      .send({ email: investor.email, password: TEST_PASSWORD });
    expect(loginRes.status).toBe(200);
    expect(loginRes.body.data.access_token).toBeDefined();
    const investorToken = loginRes.body.data.access_token;

    // 2. Verify initial wallet balances: 10,000.00 ETB available, 0.00 ETB reserved
    const initialWalletRes = await request(ctx.app)
      .get('/wallets/me')
      .set(bearer(investorToken));
    expect(initialWalletRes.status).toBe(200);
    expect(initialWalletRes.body.data.available_minor).toBe(1_000_000);
    expect(initialWalletRes.body.data.reserved_minor).toBe(0);
    expect(initialWalletRes.body.data.total_minor).toBe(1_000_000);

    // 3. Verify open IPO is discoverable
    const iposRes = await request(ctx.app)
      .get(`/ipos/${ipoId}`)
      .set(bearer(investorToken));
    expect(iposRes.status).toBe(200);
    expect(iposRes.body.data.status).toBe('open');
    expect(iposRes.body.data.price_per_share_minor).toBe(10000); // 100 ETB

    // 4. Submit a subscription for 30 shares (3,000.00 ETB = 300,000 santim)
    const idempotencyKey = `e2e-sub-${randomUUID()}`;
    const subRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investorToken))
      .set('Idempotency-Key', idempotencyKey)
      .send({
        ipo_id: ipoId,
        quantity: 30,
      });
    expect(subRes.status).toBe(201);
    expect(subRes.body.data.quantity).toBe(30);
    expect(subRes.body.data.amount_minor).toBe(300000);
    expect(subRes.body.data.status).toBe('reserved');
    const subscriptionId = subRes.body.data.id;

    // 5. Verify backend reserved funds atomically:
    // Available: 7,000.00 ETB (700,000 santim)
    // Reserved: 3,000.00 ETB (300,000 santim)
    const afterSubWalletRes = await request(ctx.app)
      .get('/wallets/me')
      .set(bearer(investorToken));
    expect(afterSubWalletRes.status).toBe(200);
    expect(afterSubWalletRes.body.data.available_minor).toBe(700_000);
    expect(afterSubWalletRes.body.data.reserved_minor).toBe(300_000);
    expect(afterSubWalletRes.body.data.total_minor).toBe(1_000_000);

    // 6. Retry the identical request with the same Idempotency-Key:
    // Returns HTTP 200 with Idempotent-Replay: true, balances unchanged
    const replayRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investorToken))
      .set('Idempotency-Key', idempotencyKey)
      .send({
        ipo_id: ipoId,
        quantity: 30,
      });
    expect(replayRes.status).toBe(200);
    expect(replayRes.headers['idempotent-replay']).toBe('true');
    expect(replayRes.body.data.id).toBe(subscriptionId);

    // Verify balances remain strictly 7,000 ETB and 3,000 ETB
    const replayWalletRes = await request(ctx.app)
      .get('/wallets/me')
      .set(bearer(investorToken));
    expect(replayWalletRes.body.data.available_minor).toBe(700_000);
    expect(replayWalletRes.body.data.reserved_minor).toBe(300_000);

    // 7. Attempt a second subscription with insufficient funds (investor2 with 7,000 ETB requests 80 shares = 8,000 ETB)
    const investor2 = await createUser(ctx, 'investor');
    await fundWallet(ctx.db, investor2.id, 700_000); // 7,000 ETB

    const failSubRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor2.token))
      .set('Idempotency-Key', `e2e-sub-${randomUUID()}`)
      .send({
        ipo_id: ipoId,
        quantity: 80, // Needs 8,000 ETB, only has 7,000 ETB
      });
    expect(failSubRes.status).toBe(422);
    expect(failSubRes.body.error.code).toBe('INSUFFICIENT_FUNDS');

    // Verify investor2 balance remains untouched
    const investor2WalletRes = await request(ctx.app)
      .get('/wallets/me')
      .set(bearer(investor2.token));
    expect(investor2WalletRes.body.data.available_minor).toBe(700_000);
    expect(investor2WalletRes.body.data.reserved_minor).toBe(0);

    // 8. Admin reviews IPO, closes it, and triggers allocation
    // 8a. Admin lists subscriptions
    const adminSubsRes = await request(ctx.app)
      .get(`/subscriptions?ipo_id=${ipoId}`)
      .set(bearer(adminToken));
    expect(adminSubsRes.status).toBe(200);
    expect(adminSubsRes.body.data).toHaveLength(1);
    expect(adminSubsRes.body.data[0].id).toBe(subscriptionId);

    // 8b. Admin closes IPO
    const closeRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/close`)
      .set(bearer(adminToken))
      .send({ reason: 'Subscription window closed' });
    expect(closeRes.status).toBe(200);
    expect(closeRes.body.data.status).toBe('closed');

    // 8c. Admin triggers allocation
    const allocateRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/allocate`)
      .set(bearer(adminToken));
    expect(allocateRes.status).toBe(200);
    expect(allocateRes.body.data.status).toBe('allocated');
    expect(allocateRes.body.data.total_shares_allocated).toBe(30);

    // 8d. Verify investor wallet after settlement:
    // Reserved is 0, Available is 7,000.00 ETB, Total is 7,000.00 ETB (3,000 settled to offering)
    const finalWalletRes = await request(ctx.app)
      .get('/wallets/me')
      .set(bearer(investorToken));
    expect(finalWalletRes.body.data.available_minor).toBe(700_000);
    expect(finalWalletRes.body.data.reserved_minor).toBe(0);
    expect(finalWalletRes.body.data.total_minor).toBe(700_000);

    // 8e. Verify audit trail records the lifecycle
    const auditRes = await request(ctx.app)
      .get('/admin/audit')
      .set(bearer(adminToken));
    expect(auditRes.status).toBe(200);
    const actions = auditRes.body.data.map((e: { action: string }) => e.action);
    expect(actions).toContain('subscription.create');
    expect(actions).toContain('ipo.close');
    expect(actions).toContain('ipo.allocate');
  });
});
