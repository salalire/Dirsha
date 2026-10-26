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

let admin: TestUser;
let investor1: TestUser;
let investor2: TestUser;
let companyRep: TestUser;
let broker: TestUser;

beforeAll(async () => {
  [admin, investor1, investor2, companyRep, broker] = await Promise.all([
    createUser(ctx, 'admin'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'company_rep'),
    createUser(ctx, 'broker'),
  ]);

  // Fund investors: 10,000 ETB (1,000,000 santim)
  await fundWallet(ctx.db, investor1.id, 1_000_000);
  await fundWallet(ctx.db, investor2.id, 1_000_000);
});

describe('Admin Access Control (FR-ADM-02, FR-ADM-04)', () => {
  it('rejects unauthenticated requests to /admin/* with 401', async () => {
    const res = await request(ctx.app).get('/admin/audit');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHENTICATED');
  });

  it('rejects non-admin roles (investor, broker, company_rep) with 403', async () => {
    for (const u of [investor1, broker, companyRep]) {
      const resAudit = await request(ctx.app)
        .get('/admin/audit')
        .set(bearer(u.token));
      expect(resAudit.status).toBe(403);
      expect(resAudit.body.error.code).toBe('FORBIDDEN');

      const resUsers = await request(ctx.app)
        .get('/admin/users')
        .set(bearer(u.token));
      expect(resUsers.status).toBe(403);
      expect(resUsers.body.error.code).toBe('FORBIDDEN');
    }
  });

  it('admin can list audit events and users (200)', async () => {
    const resAudit = await request(ctx.app)
      .get('/admin/audit')
      .set(bearer(admin.token));
    expect(resAudit.status).toBe(200);
    expect(resAudit.body.data).toBeInstanceOf(Array);
    expect(resAudit.body.pagination).toBeDefined();

    const resUsers = await request(ctx.app)
      .get('/admin/users')
      .set(bearer(admin.token));
    expect(resUsers.status).toBe(200);
    expect(resUsers.body.data.length).toBeGreaterThanOrEqual(4);
  });
});

describe('Admin IPO Review & Approval/Rejection (FR-ADM-02, FR-IPO-08)', () => {
  it('approves an IPO under review, writes status history and audit event', async () => {
    const { ipos } = await createCompanyWithIpos(ctx.db, companyRep.id, ['under_review']);
    const ipoId = ipos.under_review;

    const res = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/approve`)
      .set(bearer(admin.token))
      .send({ notes: 'All prospectus filings verified' });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({ ipo_id: ipoId, status: 'approved' });

    // Verify IPO status changed in DB
    const checkIpo = (
      await ctx.db.query<{ status: string }>('SELECT status FROM ipos WHERE id = $1', [ipoId])
    ).rows[0];
    expect(checkIpo?.status).toBe('approved');

    // Verify status history
    const history = (
      await ctx.db.query<{ from_status: string; to_status: string; changed_by: string; reason: string }>(
        'SELECT from_status, to_status, changed_by, reason FROM ipo_status_history WHERE ipo_id = $1',
        [ipoId],
      )
    ).rows[0];
    expect(history).toMatchObject({
      from_status: 'under_review',
      to_status: 'approved',
      changed_by: admin.id,
      reason: 'All prospectus filings verified',
    });
  });

  it('rejects an IPO under review with mandatory reason', async () => {
    const rep = await createUser(ctx, 'company_rep');
    const { ipos } = await createCompanyWithIpos(ctx.db, rep.id, ['under_review']);
    const ipoId = ipos.under_review;

    const res = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/reject`)
      .set(bearer(admin.token))
      .send({ reason: 'Audited financial statements missing for fiscal year' });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({ ipo_id: ipoId, status: 'rejected' });

    const checkIpo = (
      await ctx.db.query<{ status: string }>('SELECT status FROM ipos WHERE id = $1', [ipoId])
    ).rows[0];
    expect(checkIpo?.status).toBe('rejected');
  });

  it('rejects approval on an IPO in invalid status (e.g. open) with 409 CONFLICT', async () => {
    const rep = await createUser(ctx, 'company_rep');
    const { ipos } = await createCompanyWithIpos(ctx.db, rep.id, ['open']);
    const res = await request(ctx.app)
      .post(`/admin/ipos/${ipos.open}/approve`)
      .set(bearer(admin.token))
      .send({});
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CONFLICT');
  });
});

describe('Admin Pro-Rata Allocation & Settlement Engine (FR-ALC-01..02, FR-LED-03)', () => {
  it('executes deterministic pro-rata allocation for oversubscribed IPO, settling and releasing funds', async () => {
    // Create an IPO with only 25 total shares @ 100.00 ETB (10000 minor)
    const rep = await createUser(ctx, 'company_rep');
    const { ipos, companyId } = await createCompanyWithIpos(ctx.db, rep.id, ['open']);
    const ipoId = ipos.open;

    // Set total shares = 25
    await ctx.db.query(
      `UPDATE ipos
       SET total_shares = 25, price_per_share_minor = 10000,
           min_shares_per_subscription = 5, max_shares_per_subscription = 50
       WHERE id = $1`,
      [ipoId],
    );

    // Investor 1 subscribes for 30 shares (300,000 minor)
    const res1 = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor1.token))
      .set('Idempotency-Key', `alloc-sub-1-${randomUUID()}`)
      .send({ ipo_id: ipoId, quantity: 30 });
    expect(res1.status).toBe(201);
    const sub1Id = res1.body.data.id;

    // Investor 2 subscribes for 20 shares (200,000 minor)
    const res2 = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor2.token))
      .set('Idempotency-Key', `alloc-sub-2-${randomUUID()}`)
      .send({ ipo_id: ipoId, quantity: 20 });
    expect(res2.status).toBe(201);
    const sub2Id = res2.body.data.id;

    // Total requested = 50 shares. Total offered = 25 shares.
    // Pro-rata:
    // Sub 1: (30 * 25) / 50 = 15 shares (150,000 minor settled, 150,000 minor released)
    // Sub 2: (20 * 25) / 50 = 10 shares (100,000 minor settled, 100,000 minor released)
    // Total allocated = 25 shares.

    // Close IPO first
    const closeRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/close`)
      .set(bearer(admin.token));
    expect(closeRes.status).toBe(200);
    expect(closeRes.body.data.status).toBe('closed');

    // Trigger allocation
    const allocRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/allocate`)
      .set(bearer(admin.token));

    expect(allocRes.status).toBe(200);
    expect(allocRes.body.data).toMatchObject({
      ipo_id: ipoId,
      total_shares_offered: 25,
      total_shares_requested: 50,
      total_shares_allocated: 25,
      subscriptions_count: 2,
      status: 'allocated',
    });

    // Verify subscriptions in DB
    const sub1 = (
      await ctx.db.query<{ allocated_quantity: string; status: string }>(
        'SELECT allocated_quantity, status FROM subscriptions WHERE id = $1',
        [sub1Id],
      )
    ).rows[0];
    expect(sub1).toMatchObject({
      allocated_quantity: '15',
      status: 'partially_allocated',
    });

    const sub2 = (
      await ctx.db.query<{ allocated_quantity: string; status: string }>(
        'SELECT allocated_quantity, status FROM subscriptions WHERE id = $1',
        [sub2Id],
      )
    ).rows[0];
    expect(sub2).toMatchObject({
      allocated_quantity: '10',
      status: 'partially_allocated',
    });

    // Verify Investor 1 wallet:
    // Started with 1,000,000.
    // Reserved 300,000 -> available was 700,000, reserved was 300,000.
    // Settle 150,000 (reserved - 150,000) -> reserved 150,000.
    // Release 150,000 (available + 150,000, reserved - 150,000) -> available 850,000, reserved 0.
    const w1Res = await request(ctx.app)
      .get('/wallets/me')
      .set(bearer(investor1.token));
    expect(w1Res.status).toBe(200);
    expect(w1Res.body.data.available_minor).toBe(850000);
    expect(w1Res.body.data.reserved_minor).toBe(0);
    expect(w1Res.body.data.total_minor).toBe(850000);

    // Verify Investor 2 wallet:
    // Started with 1,000,000.
    // Reserved 200,000 -> available 800,000, reserved 200,000.
    // Settle 100,000 and release 100,000 -> available 900,000, reserved 0.
    const w2Res = await request(ctx.app)
      .get('/wallets/me')
      .set(bearer(investor2.token));
    expect(w2Res.status).toBe(200);
    expect(w2Res.body.data.available_minor).toBe(900000);
    expect(w2Res.body.data.reserved_minor).toBe(0);
    expect(w2Res.body.data.total_minor).toBe(900000);

    // Verify share_holdings credited atomically in DB
    const h1 = (
      await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        'SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor1.id, ipoId],
      )
    ).rows[0];
    expect(h1).toMatchObject({
      quantity: '15',
      reserved_quantity: '0',
    });

    const h2 = (
      await ctx.db.query<{ quantity: string; reserved_quantity: string }>(
        'SELECT quantity, reserved_quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor2.id, ipoId],
      )
    ).rows[0];
    expect(h2).toMatchObject({
      quantity: '10',
      reserved_quantity: '0',
    });

    // Verify wallet reconciliation across all wallets: zero broken rows
    const broken = (
      await ctx.db.query<{ n: string }>('SELECT count(*)::bigint AS n FROM wallet_reconciliation WHERE NOT ok')
    ).rows[0];
    expect(Number(broken?.n)).toBe(0);

    // Repeated allocation attempt must be rejected with 409 and not credit shares
    const reAllocRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/allocate`)
      .set(bearer(admin.token));
    expect(reAllocRes.status).toBe(409);
    expect(reAllocRes.body.error.code).toBe('CONFLICT');

    // Holdings remain unchanged
    const h1After = (
      await ctx.db.query<{ quantity: string }>(
        'SELECT quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor1.id, ipoId],
      )
    ).rows[0];
    expect(h1After?.quantity).toBe('15');

    // ── Listing Transition (Gap 2) ──────────────────────────────────────────

    // 1. Non-admin cannot list
    const nonAdminList = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/list`)
      .set(bearer(investor1.token));
    expect(nonAdminList.status).toBe(403);

    // 2. Listing an open or non-allocated IPO fails with 409
    const openIpoRes = await ctx.db.query<{ id: string }>(
      `INSERT INTO ipos (company_id, title, symbol, price_per_share_minor, total_shares, status, opens_at, closes_at)
       VALUES ($1, 'Open Offering', 'OPEN1', 10000, 1000, 'open', now() - INTERVAL '1 day', now() + INTERVAL '1 day')
       RETURNING id`,
      [companyId],
    );
    const openIpoId = openIpoRes.rows[0]!.id;
    const invalidListRes = await request(ctx.app)
      .post(`/admin/ipos/${openIpoId}/list`)
      .set(bearer(admin.token));
    expect(invalidListRes.status).toBe(409);
    expect(invalidListRes.body.error.message).toContain("Must be in 'allocated' status");

    // 3. Listing an allocated IPO with 0 shareholdings fails with 409
    const emptyAllocIpo = await ctx.db.query<{ id: string }>(
      `INSERT INTO ipos (company_id, title, symbol, price_per_share_minor, total_shares, status, opens_at, closes_at)
       VALUES ($1, 'Empty Alloc Offering', 'EMPT1', 10000, 1000, 'allocated', now() - INTERVAL '2 days', now() - INTERVAL '1 day')
       RETURNING id`,
      [companyId],
    );
    const emptyAllocId = emptyAllocIpo.rows[0]!.id;
    const emptyListRes = await request(ctx.app)
      .post(`/admin/ipos/${emptyAllocId}/list`)
      .set(bearer(admin.token));
    expect(emptyListRes.status).toBe(409);
    expect(emptyListRes.body.error.message).toContain('0 allocated shares');

    // 4. Admin successfully lists eligible allocated IPO
    const listRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/list`)
      .set(bearer(admin.token))
      .send({ reason: 'ECMA formal listing approval granted' });
    expect(listRes.status).toBe(200);
    expect(listRes.body.data).toMatchObject({
      ipo_id: ipoId,
      status: 'listed',
      total_shareholders: 2,
      total_allocated_shares: 25,
    });

    // Verify DB status
    const ipoDb = (
      await ctx.db.query<{ status: string }>('SELECT status FROM ipos WHERE id = $1', [ipoId])
    ).rows[0];
    expect(ipoDb?.status).toBe('listed');

    // Re-listing already listed IPO fails with 409
    const reListRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/list`)
      .set(bearer(admin.token));
    expect(reListRes.status).toBe(409);

    // Verify listed security appears in trading discovery
    const tradableRes = await request(ctx.app)
      .get('/trading/securities')
      .set(bearer(investor1.token));
    expect(tradableRes.status).toBe(200);
    const listedSymbols = tradableRes.body.data.map((s: { symbol: string }) => s.symbol);
    const listedIpoDb = (
      await ctx.db.query<{ symbol: string }>('SELECT symbol FROM ipos WHERE id = $1', [ipoId])
    ).rows[0];
    expect(listedSymbols).toContain(listedIpoDb?.symbol);
    expect(listedSymbols).not.toContain('OPEN1');
    expect(listedSymbols).not.toContain('EMPT1');

    // Placing order on non-listed security fails with 409
    const badOrderRes = await request(ctx.app)
      .post('/trading/orders')
      .set(bearer(investor1.token))
      .send({
        ipo_id: openIpoId,
        side: 'buy',
        order_type: 'limit',
        quantity: 5,
        price_per_share_minor: 10000,
      });
    expect(badOrderRes.status).toBe(409);
    expect(badOrderRes.body.error.message).toContain('is not listed for secondary-market trading');

    // Placing order on listed security succeeds
    const goodOrderRes = await request(ctx.app)
      .post('/trading/orders')
      .set(bearer(investor1.token))
      .send({
        ipo_id: ipoId,
        side: 'sell',
        order_type: 'limit',
        quantity: 5,
        price_per_share_minor: 10500,
      });
    expect(goodOrderRes.status).toBe(201);
    expect(goodOrderRes.body.order.status).toBe('open');
  });

  it('increments existing share holdings on subsequent allocations without overwriting', async () => {
    const rep2 = await createUser(ctx, 'company_rep');
    const { companyId } = await createCompanyWithIpos(ctx.db, rep2.id, ['open']);
    const incIpoRes = await ctx.db.query<{ id: string }>(
      `INSERT INTO ipos (company_id, title, symbol, price_per_share_minor, total_shares, min_shares_per_subscription, status, opens_at, closes_at)
       VALUES ($1, 'Tranche 2 Offering', 'TRCH2', 10000, 100, 5, 'open', now() - INTERVAL '1 day', now() + INTERVAL '1 day')
       RETURNING id`,
      [companyId],
    );
    const trchId = incIpoRes.rows[0]!.id;

    // Pre-existing holding for investor1 of 20 shares
    await ctx.db.query(
      `INSERT INTO share_holdings (investor_id, ipo_id, quantity, reserved_quantity)
       VALUES ($1, $2, 20, 0)`,
      [investor1.id, trchId],
    );

    // Investor1 subscribes for 10 shares
    const subRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor1.token))
      .set('Idempotency-Key', `inc-sub-${randomUUID()}`)
      .send({ ipo_id: trchId, quantity: 10 });
    expect(subRes.status).toBe(201);

    // Close and allocate
    await request(ctx.app).post(`/admin/ipos/${trchId}/close`).set(bearer(admin.token));
    const aRes = await request(ctx.app).post(`/admin/ipos/${trchId}/allocate`).set(bearer(admin.token));
    expect(aRes.status).toBe(200);

    // Verify holding was incremented: 20 + 10 = 30
    const h = (
      await ctx.db.query<{ quantity: string }>(
        'SELECT quantity FROM share_holdings WHERE investor_id = $1 AND ipo_id = $2',
        [investor1.id, trchId],
      )
    ).rows[0];
    expect(h?.quantity).toBe('30');
  });
});
