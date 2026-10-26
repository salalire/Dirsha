import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  buildApp,
  createUser,
  fundWallet,
  type TestCtx,
  type TestUser,
} from './helpers.js';

describe('Phase 3 End-to-End Primary & Secondary Market Acceptance Test', () => {
  let ctx: TestCtx;
  let admin: TestUser;
  let companyRep: TestUser;
  let investor1: TestUser;
  let investor2: TestUser;
  let brokerUser: TestUser;

  let companyId: string;
  let ipoId: string;
  let ipoSymbol: string;
  let brokerId: string;
  let relationshipId: string;

  beforeAll(async () => {
    ctx = buildApp();
    admin = await createUser(ctx, 'admin');
    companyRep = await createUser(ctx, 'company_rep');
    investor1 = await createUser(ctx, 'investor');
    investor2 = await createUser(ctx, 'investor');
    brokerUser = await createUser(ctx, 'broker');

    // Fund investors
    // Investor 1: 50,000 ETB (5,000,000 santim)
    // Investor 2: 50,000 ETB (5,000,000 santim)
    await fundWallet(ctx.db, investor1.id, 5_000_000);
    await fundWallet(ctx.db, investor2.id, 5_000_000);

    // Create approved broker profile
    const bRes = await ctx.db.query<{ id: string }>(
      `INSERT INTO brokers (
         owner_user_id, legal_name, license_number, license_category,
         licensing_authority, license_expiry_date, onboarding_status
       )
       VALUES ($1, 'Abyssinia Capital Partners S.C.', 'LIC-ABYS-001', 'broker_dealer', 'ECMA', '2030-01-01', 'approved')
       RETURNING id`,
      [brokerUser.id],
    );
    brokerId = bRes.rows[0]!.id;
  });

  afterAll(async () => {
    await ctx.close();
  });

  describe('Part 1: Primary-Market Workflow (Draft -> Approval -> Subscription -> Close -> Allocation -> Listing)', () => {
    it('Step 1-4: Company creates IPO, submits for approval, admin approves, and opens it', async () => {
      // 1. Create company draft
      const compRes = await ctx.db.query<{ id: string }>(
        `INSERT INTO companies (owner_user_id, legal_name, registration_number, onboarding_status)
         VALUES ($1, 'Ethio Solar Tech S.C.', 'REG-SOLAR-001', 'approved')
         RETURNING id`,
        [companyRep.id],
      );
      companyId = compRes.rows[0]!.id;

      // Create draft IPO (price = 100 ETB = 10,000 santim, total = 10,000 shares)
      ipoSymbol = `SOL${randomUUID().replace(/-/g, '').slice(0, 5).toUpperCase()}`;
      const draftRes = await request(ctx.app)
        .post('/ipos')
        .set(bearer(companyRep.token))
        .send({
          title: 'Ethio Solar Energy IPO',
          symbol: ipoSymbol,
          description: 'Expanding clean solar energy across Ethiopia',
          price_per_share_minor: 10000, // 100 ETB
          total_shares: 10000,
          min_shares_per_subscription: 5,
          max_shares_per_subscription: 1000,
          opens_at: new Date(Date.now() + 86400000).toISOString(),
          closes_at: new Date(Date.now() + 86400000 * 10).toISOString(),
        });
      expect(draftRes.status).toBe(201);
      expect(draftRes.body.data.status).toBe('draft');
      ipoId = draftRes.body.data.id;

      // 2. Submit for review
      const submitRes = await request(ctx.app)
        .post(`/ipos/${ipoId}/submit`)
        .set(bearer(companyRep.token));
      expect(submitRes.status).toBe(200);
      expect(submitRes.body.data.status).toBe('submitted');

      // 3. Admin approves IPO
      const approveRes = await request(ctx.app)
        .post(`/admin/ipos/${ipoId}/approve`)
        .set(bearer(admin.token))
        .send({ notes: 'Financials verified and approved' });
      expect(approveRes.status).toBe(200);
      expect(approveRes.body.data.status).toBe('approved');

      // 4. Open IPO (update opens_at to past so it transitions or set status to open)
      await ctx.db.query(
        `UPDATE ipos SET status = 'open', opens_at = now() - INTERVAL '1 hour' WHERE id = $1`,
        [ipoId],
      );
      const ipoCheck = await request(ctx.app)
        .get(`/ipos/${ipoId}`)
        .set(bearer(investor1.token));
      expect(ipoCheck.status).toBe(200);
      expect(ipoCheck.body.data.status).toBe('open');
    });

    it('Step 5-6: Two test investors subscribe, funds reserved in wallets', async () => {
      // Investor 1 subscribes for 50 shares (5,000 ETB = 500,000 santim)
      const sub1 = await request(ctx.app)
        .post('/subscriptions')
        .set(bearer(investor1.token))
        .set('Idempotency-Key', `sub1-${randomUUID()}`)
        .send({ ipo_id: ipoId, quantity: 50 });
      expect(sub1.status).toBe(201);
      expect(sub1.body.data.status).toBe('reserved');
      expect(sub1.body.data.quantity).toBe(50);
      expect(sub1.body.data.amount_minor).toBe(500000);

      // Investor 2 subscribes for 30 shares (3,000 ETB = 300,000 santim)
      const sub2 = await request(ctx.app)
        .post('/subscriptions')
        .set(bearer(investor2.token))
        .set('Idempotency-Key', `sub2-${randomUUID()}`)
        .send({ ipo_id: ipoId, quantity: 30 });
      expect(sub2.status).toBe(201);
      expect(sub2.body.data.status).toBe('reserved');
      expect(sub2.body.data.quantity).toBe(30);
      expect(sub2.body.data.amount_minor).toBe(300000);

      // Check investor 1 wallet reservation:
      // Available: 5,000,000 - 500,000 = 4,500,000 santim
      // Reserved: 500,000 santim
      const w1 = await request(ctx.app).get('/wallets/me').set(bearer(investor1.token));
      expect(w1.body.data.available_minor).toBe(4_500_000);
      expect(w1.body.data.reserved_minor).toBe(500_000);

      // Check investor 2 wallet reservation:
      // Available: 5,000,000 - 300,000 = 4,700,000 santim
      // Reserved: 300,000 santim
      const w2 = await request(ctx.app).get('/wallets/me').set(bearer(investor2.token));
      expect(w2.body.data.available_minor).toBe(4_700_000);
      expect(w2.body.data.reserved_minor).toBe(300_000);
    });

    it('Step 7: Admin closes the IPO', async () => {
      const closeRes = await request(ctx.app)
        .post(`/admin/ipos/${ipoId}/close`)
        .set(bearer(admin.token))
        .send({ reason: 'Subscription target reached' });
      expect(closeRes.status).toBe(200);
      expect(closeRes.body.data.status).toBe('closed');
    });

    it('Step 8-10: Admin allocates shares, updates share_holdings atomically, and verifies ledger reconciliation', async () => {
      const allocRes = await request(ctx.app)
        .post(`/admin/ipos/${ipoId}/allocate`)
        .set(bearer(admin.token));
      expect(allocRes.status).toBe(200);
      expect(allocRes.body.data.status).toBe('allocated');
      expect(allocRes.body.data.total_shares_allocated).toBe(80);

      // 9. Verify each investor's allocated quantity in share_holdings
      const h1 = await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        'SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor1.id, ipoId],
      );
      expect(h1.rows).toHaveLength(1);
      expect(Number(h1.rows[0]!.quantity)).toBe(50);
      expect(Number(h1.rows[0]!.reserved_quantity)).toBe(0);

      const h2 = await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        'SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor2.id, ipoId],
      );
      expect(h2.rows).toHaveLength(1);
      expect(Number(h2.rows[0]!.quantity)).toBe(30);
      expect(Number(h2.rows[0]!.reserved_quantity)).toBe(0);

      // Verify wallet settlement
      const w1 = await request(ctx.app).get('/wallets/me').set(bearer(investor1.token));
      expect(w1.body.data.available_minor).toBe(4_500_000);
      expect(w1.body.data.reserved_minor).toBe(0);
      expect(w1.body.data.total_minor).toBe(4_500_000);

      const w2 = await request(ctx.app).get('/wallets/me').set(bearer(investor2.token));
      expect(w2.body.data.available_minor).toBe(4_700_000);
      expect(w2.body.data.reserved_minor).toBe(0);
      expect(w2.body.data.total_minor).toBe(4_700_000);

      // Verify wallet reconciliation across all wallets
      const recon = await ctx.db.query<{ unallocated_difference_count: string }>(
        `SELECT COUNT(*) AS unallocated_difference_count
         FROM wallets w
         LEFT JOIN (
           SELECT wallet_id,
                  COALESCE(SUM(available_delta_minor), 0) AS calc_avail,
                  COALESCE(SUM(reserved_delta_minor), 0) AS calc_res
           FROM ledger_entries
           GROUP BY wallet_id
         ) le ON le.wallet_id = w.id
         WHERE (w.available_minor != COALESCE(le.calc_avail, 0)
            OR w.reserved_minor != COALESCE(le.calc_res, 0))`,
      );
      expect(Number(recon.rows[0]!.unallocated_difference_count)).toBe(0);
    });

    it('Step 11: Repeated allocation attempt is rejected with 409 and cannot credit shares twice', async () => {
      const repeatRes = await request(ctx.app)
        .post(`/admin/ipos/${ipoId}/allocate`)
        .set(bearer(admin.token));
      expect(repeatRes.status).toBe(409);
      expect(repeatRes.body.error.code).toBe('CONFLICT');

      // Verify shareholdings remain strictly 50 and 30
      const h1 = await ctx.db.query<{ quantity: string }>(
        'SELECT quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor1.id, ipoId],
      );
      expect(Number(h1.rows[0]!.quantity)).toBe(50);
    });

    it('Step 12-13: Admin lists the allocated IPO and it appears in trading discovery', async () => {
      // Prior to listing, check that trading discovery does not show the IPO
      const beforeList = await request(ctx.app)
        .get('/trading/securities')
        .set(bearer(investor1.token));
      expect(beforeList.status).toBe(200);
      const isPresentBefore = beforeList.body.data.some((s: { ipo_id: string }) => s.ipo_id === ipoId);
      expect(isPresentBefore).toBe(false);

      // Admin lists the IPO
      const listRes = await request(ctx.app)
        .post(`/admin/ipos/${ipoId}/list`)
        .set(bearer(admin.token))
        .send({ reason: 'Secondary market trading opened' });
      expect(listRes.status).toBe(200);
      expect(listRes.body.data.status).toBe('listed');

      // Now verify it appears in trading discovery
      const afterList = await request(ctx.app)
        .get('/trading/securities')
        .set(bearer(investor1.token));
      expect(afterList.status).toBe(200);
      const foundSec = afterList.body.data.find((s: { ipo_id: string }) => s.ipo_id === ipoId);
      expect(foundSec).toBeDefined();
      expect(foundSec.symbol).toBe(ipoSymbol);
      expect(foundSec.company_name).toBe('Ethio Solar Tech S.C.');
    });
  });

  describe('Part 2: Secondary-Market Workflow (Trading, Matching Engine, Consent & Validation)', () => {
    it('Rejects order placement on unlisted or non-existent security', async () => {
      // Create a draft unlisted IPO
      const unlistedSymbol = `UNL${randomUUID().replace(/-/g, '').slice(0, 5).toUpperCase()}`;
      const draftRes = await request(ctx.app)
        .post('/ipos')
        .set(bearer(companyRep.token))
        .send({
          title: 'Unlisted Venture IPO',
          symbol: unlistedSymbol,
          price_per_share_minor: 5000,
          total_shares: 500,
          min_shares_per_subscription: 1,
          max_shares_per_subscription: 50,
          opens_at: new Date(Date.now() + 86400000).toISOString(),
          closes_at: new Date(Date.now() + 86400000 * 5).toISOString(),
        });
      const unlistedIpoId = draftRes.body.data.id;

      const orderRes = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investor1.token))
        .send({
          ipo_id: unlistedIpoId,
          side: 'buy',
          order_type: 'limit',
          price_per_share_minor: 5000,
          quantity: 10,
        });
      expect(orderRes.status).toBe(409);
      expect(orderRes.body.error.message).toContain('not listed for secondary-market trading');
    });

    it('Rejects sell order when seller has insufficient shares', async () => {
      // Investor 2 has 30 shares. Attempt to sell 100 shares.
      const failSell = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investor2.token))
        .send({
          ipo_id: ipoId,
          side: 'sell',
          order_type: 'limit',
          price_per_share_minor: 11000, // 110 ETB
          quantity: 100,
        });
      expect(failSell.status).toBe(400);
      expect(failSell.body.error.details[0].message).toContain('Insufficient available shares');
    });

    it('Rejects buy order when buyer has insufficient funds', async () => {
      // Create a broke investor with 0 funds
      const brokeInvestor = await createUser(ctx, 'investor');
      const failBuy = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(brokeInvestor.token))
        .send({
          ipo_id: ipoId,
          side: 'buy',
          order_type: 'limit',
          price_per_share_minor: 10000,
          quantity: 10,
        });
      expect(failBuy.status).toBe(422);
      expect(failBuy.body.error.message).toContain('Available balance is not enough');
    });

    it('Executes secondary-market matching: sell order posted, matching buy order fills atomically', async () => {
      // Investor 1 places limit sell order for 10 shares @ 105 ETB (10,500 santim)
      // Investor 1 has 50 shares available.
      const sellRes = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investor1.token))
        .send({
          ipo_id: ipoId,
          side: 'sell',
          order_type: 'limit',
          price_per_share_minor: 10500,
          quantity: 10,
        });
      expect(sellRes.status).toBe(201);
      expect(sellRes.body.order.status).toBe('open');
      expect(sellRes.body.order.quantity).toBe(10);
      expect(sellRes.body.order.filled_quantity).toBe(0);

      // Verify Investor 1 reserved 10 shares
      const h1AfterSell = await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        'SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor1.id, ipoId],
      );
      expect(Number(h1AfterSell.rows[0]!.quantity)).toBe(50);
      expect(Number(h1AfterSell.rows[0]!.reserved_quantity)).toBe(10);

      // Investor 2 places matching buy order for 10 shares @ 105 ETB (10,500 santim)
      const buyRes = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investor2.token))
        .send({
          ipo_id: ipoId,
          side: 'buy',
          order_type: 'limit',
          price_per_share_minor: 10500,
          quantity: 10,
        });
      expect(buyRes.status).toBe(201);
      expect(buyRes.body.order.status).toBe('filled');
      expect(buyRes.body.order.filled_quantity).toBe(10);
      expect(buyRes.body.trades).toHaveLength(1);
      expect(buyRes.body.trades[0].quantity).toBe(10);
      expect(buyRes.body.trades[0].price_per_share_minor).toBe(10500);

      // Verify shareholdings post-trade:
      // Investor 1: quantity reduced to 40, reserved 0
      const h1Post = await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        'SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor1.id, ipoId],
      );
      expect(Number(h1Post.rows[0]!.quantity)).toBe(40);
      expect(Number(h1Post.rows[0]!.reserved_quantity)).toBe(0);

      // Investor 2: quantity increased from 30 to 40
      const h2Post = await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        'SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor2.id, ipoId],
      );
      expect(Number(h2Post.rows[0]!.quantity)).toBe(40);

      // Verify cash settlement:
      // Trade amount = 10 * 10,500 = 105,000 santim (1,050 ETB)
      // Investor 1 (seller): +105,000 santim (4,500,000 + 105,000 = 4,605,000 santim)
      const w1Post = await request(ctx.app).get('/wallets/me').set(bearer(investor1.token));
      expect(w1Post.body.data.available_minor).toBe(4_605_000);

      // Investor 2 (buyer): -105,000 santim (4,700,000 - 105,000 = 4,595,000 santim)
      const w2Post = await request(ctx.app).get('/wallets/me').set(bearer(investor2.token));
      expect(w2Post.body.data.available_minor).toBe(4_595_000);

      // Check trade history
      const tradesRes = await request(ctx.app)
        .get('/trading/trades')
        .set(bearer(investor1.token));
      expect(tradesRes.status).toBe(200);
      expect(tradesRes.body.data.length).toBeGreaterThanOrEqual(1);
    });

    it('Step 7: Broker-assisted trading enforces active consent lifecycle (Pending -> Denied -> Active -> Executed -> Revoked -> Denied)', async () => {
      // 1. Broker requests relationship with Investor 1
      const reqRel = await request(ctx.app)
        .post('/brokers/clients/request')
        .set(bearer(brokerUser.token))
        .send({
          investor_email: investor1.email,
          relationship_type: 'advisory',
          notes: 'Client trading representation',
        });
      expect(reqRel.status).toBe(201);
      expect(reqRel.body.status).toBe('pending');
      relationshipId = reqRel.body.id;

      // 2. Pending consent: Broker cannot place order on behalf of Investor 1
      const pendingOrder = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(brokerUser.token))
        .send({
          ipo_id: ipoId,
          side: 'buy',
          order_type: 'limit',
          price_per_share_minor: 10000,
          quantity: 5,
          client_id: investor1.id,
        });
      expect(pendingOrder.status).toBe(403);
      expect(pendingOrder.body.error.message).toContain('Active client authorization is required');

      // 3. Investor 1 accepts relationship request
      const acceptRes = await request(ctx.app)
        .post(`/brokers/relationships/${relationshipId}/respond`)
        .set(bearer(investor1.token))
        .send({ action: 'accept' });
      expect(acceptRes.status).toBe(200);
      expect(acceptRes.body.status).toBe('active');

      // 4. Active consent: Broker places client-assisted buy order for 5 shares @ 100 ETB
      const assistedOrder = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(brokerUser.token))
        .send({
          ipo_id: ipoId,
          side: 'buy',
          order_type: 'limit',
          price_per_share_minor: 10000,
          quantity: 5,
          client_id: investor1.id,
        });
      expect(assistedOrder.status).toBe(201);
      expect(assistedOrder.body.order.status).toBe('open');
      expect(assistedOrder.body.order.assisted_by_broker_id).toBe(brokerId);
      const assistedOrderId = assistedOrder.body.order.id;

      // Broker can cancel the assisted order on behalf of client
      const cancelRes = await request(ctx.app)
        .post(`/trading/orders/${assistedOrderId}/cancel`)
        .set(bearer(brokerUser.token));
      expect(cancelRes.status).toBe(200);
      expect(cancelRes.body.status).toBe('cancelled');

      // 5. Investor 1 revokes relationship
      const revokeRes = await request(ctx.app)
        .post(`/brokers/relationships/${relationshipId}/respond`)
        .set(bearer(investor1.token))
        .send({ action: 'revoke' });
      expect(revokeRes.status).toBe(200);
      expect(revokeRes.body.status).toBe('revoked');

      // 6. Revoked consent: Broker can no longer place orders for Investor 1
      const postRevokeOrder = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(brokerUser.token))
        .send({
          ipo_id: ipoId,
          side: 'buy',
          order_type: 'limit',
          price_per_share_minor: 10000,
          quantity: 5,
          client_id: investor1.id,
        });
      expect(postRevokeOrder.status).toBe(403);
      expect(postRevokeOrder.body.error.message).toContain('Active client authorization is required');
    });
  });
});
