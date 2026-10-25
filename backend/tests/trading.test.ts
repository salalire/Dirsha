import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { bearer, buildApp, createUser, fundWallet, type TestUser } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

let admin: TestUser;
let investorBuyer: TestUser;
let investorSeller: TestUser;
let unauthorizedUser: TestUser;
let brokerUser: TestUser;

let brokerId: string;
let testIpoId: string;
let buyerWalletId: string;
let sellerWalletId: string;

beforeAll(async () => {
  [admin, investorBuyer, investorSeller, unauthorizedUser, brokerUser] = await Promise.all([
    createUser(ctx, 'admin'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'broker'),
  ]);

  // Create approved broker
  const bRes = await ctx.db.query<{ id: string }>(
    `INSERT INTO brokers (owner_user_id, legal_name, license_number, license_category, licensing_authority, license_expiry_date, onboarding_status)
     VALUES ($1, 'Ethio-Alliance Securities S.C.', 'LIC-ALLIANCE-01', 'broker_dealer', 'ECMA', '2030-01-01', 'approved')
     RETURNING id`,
    [brokerUser.id],
  );
  brokerId = bRes.rows[0]!.id;

  // Active broker-client relationship with investorBuyer
  await ctx.db.query(
    `INSERT INTO broker_client_relationships (broker_id, investor_id, relationship_type, status, requested_by)
     VALUES ($1, $2, 'discretionary', 'active', 'broker')`,
    [brokerId, investorBuyer.id],
  );

  // Create an active company and an open IPO
  const comp = await ctx.db.query<{ id: string }>(
    `INSERT INTO companies (owner_user_id, legal_name, registration_number, onboarding_status)
     VALUES ($1, 'Habesha Breweries S.C.', 'REG-BEER-01', 'approved')
     RETURNING id`,
    [admin.id],
  );
  const companyId = comp.rows[0]!.id;

  const ipo = await ctx.db.query<{ id: string }>(
    `INSERT INTO ipos (
       company_id, title, symbol, price_per_share_minor, total_shares,
       status, opens_at, closes_at
     )
     VALUES (
       $1, 'Habesha Breweries Shares', 'HBBR', 10000, 500000,
       'open', now() - INTERVAL '1 day', now() + INTERVAL '10 days'
     )
     RETURNING id`,
    [companyId],
  );
  testIpoId = ipo.rows[0]!.id;

  // Seed buyer's wallet: 5,000,000 minor (50,000 ETB) via ledger
  buyerWalletId = await fundWallet(ctx.db, investorBuyer.id, 5000000);

  // Seed seller's wallet: 1,000,000 minor (10,000 ETB) via ledger
  sellerWalletId = await fundWallet(ctx.db, investorSeller.id, 1000000);

  // Seed seller's share holdings: 1,000 shares
  await ctx.db.query(
    `INSERT INTO share_holdings (investor_id, ipo_id, quantity, reserved_quantity)
     VALUES ($1, $2, 1000, 0)
     ON CONFLICT (investor_id, ipo_id) DO UPDATE SET quantity = 1000, reserved_quantity = 0`,
    [investorSeller.id, testIpoId],
  );
});

describe('Simulated Secondary-Market Trading Engine (Task E)', () => {
  describe('Market Overview & Holdings Discovery', () => {
    it('lists tradable securities with open order stats', async () => {
      const res = await request(ctx.app)
        .get('/trading/securities')
        .set(bearer(investorBuyer.token));
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
      const security = res.body.data.find((s: { ipo_id: string }) => s.ipo_id === testIpoId);
      expect(security).toBeDefined();
      expect(security.symbol).toBe('HBBR');
      expect(security.price_per_share_minor).toBe(10000);
    });

    it('lists own share holdings with available and reserved quantities', async () => {
      const res = await request(ctx.app)
        .get('/trading/holdings')
        .set(bearer(investorSeller.token));
      expect(res.status).toBe(200);
      const holding = res.body.data.find((h: { ipo_id: string }) => h.ipo_id === testIpoId);
      expect(holding).toBeDefined();
      expect(holding.quantity).toBe(1000);
      expect(holding.reserved_quantity).toBe(0);
      expect(holding.available_quantity).toBe(1000);
    });
  });

  describe('Order Placement, Share Reservation & Concurrency Checks', () => {
    it('rejects sell order exceeding available share holdings', async () => {
      const res = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investorSeller.token))
        .send({
          ipo_id: testIpoId,
          side: 'sell',
          price_per_share_minor: 10000,
          quantity: 2000, // owns only 1000
        });
      expect(res.status).toBe(400);
      expect(res.body.error.details[0].message).toContain('Insufficient available shares');
    });

    it('places sell order and reserves shares without matching when no opposite orders exist', async () => {
      const res = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investorSeller.token))
        .send({
          ipo_id: testIpoId,
          side: 'sell',
          price_per_share_minor: 10000,
          quantity: 300,
        });
      expect(res.status).toBe(201);
      expect(res.body.order.status).toBe('open');
      expect(res.body.order.filled_quantity).toBe(0);
      expect(res.body.trades.length).toBe(0);

      // Verify seller holdings has 300 reserved, 700 available
      const hRes = await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        `SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2`,
        [investorSeller.id, testIpoId],
      );
      expect(Number(hRes.rows[0]!.quantity)).toBe(1000);
      expect(Number(hRes.rows[0]!.reserved_quantity)).toBe(300);
    });

    it('rejects buy order when buyer has insufficient cash balance', async () => {
      const res = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investorBuyer.token))
        .send({
          ipo_id: testIpoId,
          side: 'buy',
          price_per_share_minor: 10000,
          quantity: 10000, // 100,000,000 minor needed, only has 5,000,000
        });
      expect(res.status).toBe(422);
      expect(res.body.error.code).toBe('INSUFFICIENT_FUNDS');
    });
  });

  describe('Deterministic Order Matching, Execution & Ledger Settlement', () => {
    it('executes match when buyer limit price meets seller price, settling cash and transferring shares', async () => {
      // Seller has 300 shares selling @ 10000 minor.
      // Buyer places buy order for 200 shares @ 10000 minor.
      const res = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investorBuyer.token))
        .send({
          ipo_id: testIpoId,
          side: 'buy',
          price_per_share_minor: 10000,
          quantity: 200,
        });

      expect(res.status).toBe(201);
      expect(res.body.order.status).toBe('filled');
      expect(res.body.order.filled_quantity).toBe(200);
      expect(res.body.trades.length).toBe(1);

      const trade = res.body.trades[0];
      expect(trade.quantity).toBe(200);
      expect(trade.price_per_share_minor).toBe(10000);
      expect(trade.total_amount_minor).toBe(2000000);
      expect(trade.buyer_user_id).toBe(investorBuyer.id);
      expect(trade.seller_user_id).toBe(investorSeller.id);

      // Verify Buyer's share holdings: now owns 200 shares
      const buyerHoldings = await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        `SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2`,
        [investorBuyer.id, testIpoId],
      );
      expect(Number(buyerHoldings.rows[0]!.quantity)).toBe(200);
      expect(Number(buyerHoldings.rows[0]!.reserved_quantity)).toBe(0);

      // Verify Seller's share holdings: quantity reduced to 800, reserved remaining = 100
      const sellerHoldings = await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        `SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2`,
        [investorSeller.id, testIpoId],
      );
      expect(Number(sellerHoldings.rows[0]!.quantity)).toBe(800);
      expect(Number(sellerHoldings.rows[0]!.reserved_quantity)).toBe(100);

      // Verify Seller's wallet: received 2,000,000 minor (was 1,000,000 -> now 3,000,000)
      const sellerWallet = await ctx.db.query<{ available_minor: string }>(
        `SELECT available_minor FROM wallets WHERE id = $1`,
        [sellerWalletId],
      );
      expect(Number(sellerWallet.rows[0]!.available_minor)).toBe(3000000);

      // Verify Buyer's wallet: spent 2,000,000 minor (was 5,000,000 -> now 3,000,000)
      const buyerWallet = await ctx.db.query<{ available_minor: string }>(
        `SELECT available_minor FROM wallets WHERE id = $1`,
        [buyerWalletId],
      );
      expect(Number(buyerWallet.rows[0]!.available_minor)).toBe(3000000);

      // Verify wallet reconciliation view remains 100% OK!
      const recon = await ctx.db.query<{ ok: boolean }>(
        `SELECT ok FROM wallet_reconciliation WHERE wallet_id IN ($1, $2)`,
        [buyerWalletId, sellerWalletId],
      );
      expect(recon.rows.every((r) => r.ok)).toBe(true);
    });

    it('matches with price improvement refund when buyer limit price exceeds seller offer', async () => {
      // Seller still has 100 shares selling @ 10000 minor.
      // Buyer offers 10500 minor for 100 shares.
      // Match price is maker price (10000 minor).
      // Buyer gets 500 * 100 = 50000 minor refunded back to available cash!
      const res = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investorBuyer.token))
        .send({
          ipo_id: testIpoId,
          side: 'buy',
          price_per_share_minor: 10500,
          quantity: 100,
        });

      expect(res.status).toBe(201);
      expect(res.body.order.status).toBe('filled');
      expect(res.body.trades.length).toBe(1);
      expect(res.body.trades[0].price_per_share_minor).toBe(10000);
      expect(res.body.trades[0].total_amount_minor).toBe(1000000);

      // Wallet reconciliation check
      const recon = await ctx.db.query<{ ok: boolean }>(
        `SELECT ok FROM wallet_reconciliation WHERE wallet_id IN ($1, $2)`,
        [buyerWalletId, sellerWalletId],
      );
      expect(recon.rows.every((r) => r.ok)).toBe(true);
    });
  });

  describe('Order Cancellation & Asset Release', () => {
    it('cancels open sell order and releases reserved shares back to available balance', async () => {
      const createRes = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investorSeller.token))
        .send({
          ipo_id: testIpoId,
          side: 'sell',
          price_per_share_minor: 12000,
          quantity: 50,
        });
      const orderId = createRes.body.order.id;

      // Cancel order
      const cancelRes = await request(ctx.app)
        .post(`/trading/orders/${orderId}/cancel`)
        .set(bearer(investorSeller.token));
      expect(cancelRes.status).toBe(200);
      expect(cancelRes.body.status).toBe('cancelled');

      // Verify shares unreserved
      const hRes = await ctx.db.query<{ reserved_quantity: string }>(
        `SELECT reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2`,
        [investorSeller.id, testIpoId],
      );
      expect(Number(hRes.rows[0]!.reserved_quantity)).toBe(0);
    });

    it('cancels open buy order and releases reserved cash back to available balance', async () => {
      const createRes = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investorBuyer.token))
        .send({
          ipo_id: testIpoId,
          side: 'buy',
          price_per_share_minor: 8000,
          quantity: 50, // reserves 400,000 minor
        });
      const orderId = createRes.body.order.id;

      const cancelRes = await request(ctx.app)
        .post(`/trading/orders/${orderId}/cancel`)
        .set(bearer(investorBuyer.token));
      expect(cancelRes.status).toBe(200);
      expect(cancelRes.body.status).toBe('cancelled');

      // Verify ledger reconciliation remains strictly OK
      const recon = await ctx.db.query<{ ok: boolean }>(
        `SELECT ok FROM wallet_reconciliation WHERE wallet_id = $1`,
        [buyerWalletId],
      );
      expect(recon.rows[0]!.ok).toBe(true);
    });

    it('rejects cancellation of already cancelled order', async () => {
      const createRes = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(investorBuyer.token))
        .send({
          ipo_id: testIpoId,
          side: 'buy',
          price_per_share_minor: 8000,
          quantity: 10,
        });
      const orderId = createRes.body.order.id;

      await request(ctx.app)
        .post(`/trading/orders/${orderId}/cancel`)
        .set(bearer(investorBuyer.token));

      const repeatCancel = await request(ctx.app)
        .post(`/trading/orders/${orderId}/cancel`)
        .set(bearer(investorBuyer.token));
      expect(repeatCancel.status).toBe(409);
    });
  });

  describe('Broker-Assisted Trading & Authorization Boundaries', () => {
    it('authorized broker can inspect client share holdings', async () => {
      const res = await request(ctx.app)
        .get(`/trading/holdings?client_id=${investorBuyer.id}`)
        .set(bearer(brokerUser.token));
      expect(res.status).toBe(200);
      const holding = res.body.data.find((h: { ipo_id: string }) => h.ipo_id === testIpoId);
      expect(holding).toBeDefined();
      expect(holding.quantity).toBe(300); // 200 from first trade + 100 from second trade
    });

    it('authorized broker can place simulated order on behalf of active client', async () => {
      const res = await request(ctx.app)
        .post('/trading/orders')
        .set(bearer(brokerUser.token))
        .send({
          ipo_id: testIpoId,
          side: 'buy',
          price_per_share_minor: 9000,
          quantity: 20,
          client_id: investorBuyer.id,
        });

      expect(res.status).toBe(201);
      expect(res.body.order.user_id).toBe(investorBuyer.id);
      expect(res.body.order.assisted_by_broker_id).toBe(brokerId);
    });

    it('forbids unauthorized investor from querying another investor client holdings', async () => {
      const res = await request(ctx.app)
        .get(`/trading/holdings?client_id=${investorBuyer.id}`)
        .set(bearer(unauthorizedUser.token));
      expect(res.status).toBe(403);
    });

    it('lists orders and execution trades history with filters', async () => {
      const ordersRes = await request(ctx.app)
        .get('/trading/orders')
        .set(bearer(investorBuyer.token));
      expect(ordersRes.status).toBe(200);
      expect(ordersRes.body.data.length).toBeGreaterThanOrEqual(1);

      const tradesRes = await request(ctx.app)
        .get('/trading/trades')
        .set(bearer(investorBuyer.token));
      expect(tradesRes.status).toBe(200);
      expect(tradesRes.body.data.length).toBeGreaterThanOrEqual(2);
    });
  });
});
