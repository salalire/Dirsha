import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  buildApp,
  createUser,
  fundWallet,
  type TestUser,
} from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

let admin: TestUser;
let investor: TestUser;
let companyRep: TestUser;
let broker: TestUser;
let companyId: string;

beforeAll(async () => {
  [admin, investor, companyRep, broker] = await Promise.all([
    createUser(ctx, 'admin'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'company_rep'),
    createUser(ctx, 'broker'),
  ]);

  // Fund investor with 10,000 ETB (1,000,000 santim)
  await fundWallet(ctx.db, investor.id, 1_000_000);

  // Create an approved company
  const companyRow = (
    await ctx.db.query<{ id: string }>(
      `INSERT INTO companies (owner_user_id, legal_name, registration_number, onboarding_status)
       VALUES ($1, $2, $3, 'approved') RETURNING id`,
      [companyRep.id, `Workflow Test Co ${randomUUID().slice(0, 8)}`, `REG-${randomUUID()}`],
    )
  ).rows[0];
  if (!companyRow) throw new Error('Company creation failed');
  companyId = companyRow.id;
});

describe('IPO Approval & Subscription Opening Workflow (FR-IPO-05, FR-IPO-06, FR-ADM-02)', () => {
  it('approving an offering with opens_at <= now() opens subscriptions immediately', async () => {
    // Offering submitted with opens_at in the past / current
    const ipoRow = (
      await ctx.db.query<{ id: string }>(
        `INSERT INTO ipos (company_id, title, symbol, price_per_share_minor, total_shares,
                           opens_at, closes_at, status)
         VALUES ($1, 'Immediate Open IPO', $2, 10000, 1000, now() - interval '5 minutes', now() + interval '7 days', 'under_review')
         RETURNING id`,
        [companyId, `OPN${randomUUID().replace(/-/g, '').slice(0, 7)}`],
      )
    ).rows[0];
    const ipoId = ipoRow!.id;

    // Approve the IPO
    const approveRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/approve`)
      .set(bearer(admin.token))
      .send({ notes: 'Filing reviewed and verified' });

    expect(approveRes.status).toBe(200);

    // Verify public view via GET /ipos/:id returns status: 'open'
    const getRes = await request(ctx.app)
      .get(`/ipos/${ipoId}`)
      .set(bearer(investor.token));

    expect(getRes.status).toBe(200);
    expect(getRes.body.data.status).toBe('open');

    // Investor can immediately subscribe
    const subRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `sub-${randomUUID()}`)
      .send({ ipo_id: ipoId, quantity: 10 });

    expect(subRes.status).toBe(201);
    expect(subRes.body.data.quantity).toBe(10);
    expect(subRes.body.data.status).toBe('reserved');
  });

  it('approving with open_immediately: true opens subscriptions even if opens_at was in future', async () => {
    // Offering submitted with future opens_at (e.g. tomorrow)
    const ipoRow = (
      await ctx.db.query<{ id: string }>(
        `INSERT INTO ipos (company_id, title, symbol, price_per_share_minor, total_shares,
                           opens_at, closes_at, status)
         VALUES ($1, 'Future Scheduled IPO', $2, 10000, 1000, now() + interval '1 day', now() + interval '14 days', 'under_review')
         RETURNING id`,
        [companyId, `FUT${randomUUID().replace(/-/g, '').slice(0, 7)}`],
      )
    ).rows[0];
    const ipoId = ipoRow!.id;

    // Approve with open_immediately: true
    const approveRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/approve`)
      .set(bearer(admin.token))
      .send({ notes: 'Approved for immediate launch', open_immediately: true });

    expect(approveRes.status).toBe(200);
    expect(approveRes.body.data.status).toBe('open');

    // In DB, status is open and opens_at has been advanced to <= now()
    const dbIpo = (
      await ctx.db.query<{ status: string; opens_at: Date }>(
        'SELECT status, opens_at FROM ipos WHERE id = $1',
        [ipoId],
      )
    ).rows[0];
    expect(dbIpo?.status).toBe('open');
    expect(new Date(dbIpo!.opens_at).getTime()).toBeLessThanOrEqual(Date.now() + 1000);

    // Investor can subscribe
    const subRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `sub-${randomUUID()}`)
      .send({ ipo_id: ipoId, quantity: 5 });

    expect(subRes.status).toBe(201);
    expect(subRes.body.data.quantity).toBe(5);
    expect(subRes.body.data.status).toBe('reserved');
  });

  it('approving a future-dated offering without open_immediately stays approved until opened', async () => {
    // Offering submitted with future opens_at
    const ipoRow = (
      await ctx.db.query<{ id: string }>(
        `INSERT INTO ipos (company_id, title, symbol, price_per_share_minor, total_shares,
                           opens_at, closes_at, status)
         VALUES ($1, 'Scheduled IPO', $2, 10000, 1000, now() + interval '3 days', now() + interval '14 days', 'under_review')
         RETURNING id`,
        [companyId, `SCH${randomUUID().replace(/-/g, '').slice(0, 7)}`],
      )
    ).rows[0];
    const ipoId = ipoRow!.id;

    // Standard approval
    const approveRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/approve`)
      .set(bearer(admin.token))
      .send({ notes: 'Filing approved for scheduled release' });

    expect(approveRes.status).toBe(200);
    expect(approveRes.body.data.status).toBe('approved');

    // Investor checking IPO sees approved status
    const getRes = await request(ctx.app)
      .get(`/ipos/${ipoId}`)
      .set(bearer(investor.token));

    expect(getRes.status).toBe(200);
    expect(getRes.body.data.status).toBe('approved');

    // Pre-opening subscription attempts return 409 conflict
    const earlySubRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `sub-${randomUUID()}`)
      .send({ ipo_id: ipoId, quantity: 10 });

    expect(earlySubRes.status).toBe(422);
    expect(earlySubRes.body.error.code).toBe('IPO_NOT_OPEN');

    // Admin opens the offering via POST /admin/ipos/:id/open
    const openRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/open`)
      .set(bearer(admin.token))
      .send({ reason: 'Opening subscriptions early by admin decision' });

    expect(openRes.status).toBe(200);
    expect(openRes.body.data.status).toBe('open');

    // Verify status history has both approved and open transitions
    const history = (
      await ctx.db.query<{ to_status: string }>(
        'SELECT to_status FROM ipo_status_history WHERE ipo_id = $1 ORDER BY created_at ASC',
        [ipoId],
      )
    ).rows;
    const historyStatuses = history.map((h) => h.to_status);
    expect(historyStatuses).toContain('approved');
    expect(historyStatuses).toContain('open');

    // Now subscription succeeds
    const nowSubRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `sub-${randomUUID()}`)
      .send({ ipo_id: ipoId, quantity: 10 });

    expect(nowSubRes.status).toBe(201);
    expect(nowSubRes.body.data.quantity).toBe(10);
    expect(nowSubRes.body.data.status).toBe('reserved');
  });

  it('rejects subscriptions once an IPO is closed', async () => {
    const ipoRow = (
      await ctx.db.query<{ id: string }>(
        `INSERT INTO ipos (company_id, title, symbol, price_per_share_minor, total_shares,
                           opens_at, closes_at, status)
         VALUES ($1, 'Closing Test IPO', $2, 10000, 1000, now() - interval '2 days', now() + interval '5 days', 'open')
         RETURNING id`,
        [companyId, `CLS${randomUUID().replace(/-/g, '').slice(0, 7)}`],
      )
    ).rows[0];
    const ipoId = ipoRow!.id;

    // Admin closes IPO
    const closeRes = await request(ctx.app)
      .post(`/admin/ipos/${ipoId}/close`)
      .set(bearer(admin.token))
      .send({ reason: 'Offering period concluded' });

    expect(closeRes.status).toBe(200);
    expect(closeRes.body.data.status).toBe('closed');

    // Subscription attempt rejected
    const subRes = await request(ctx.app)
      .post('/subscriptions')
      .set(bearer(investor.token))
      .set('Idempotency-Key', `sub-${randomUUID()}`)
      .send({ ipo_id: ipoId, quantity: 10 });

    expect(subRes.status).toBe(422);
    expect(subRes.body.error.code).toBe('IPO_NOT_OPEN');
  });

  it('enforces RBAC on approve and open operations', async () => {
    const ipoRow = (
      await ctx.db.query<{ id: string }>(
        `INSERT INTO ipos (company_id, title, symbol, price_per_share_minor, total_shares,
                           opens_at, closes_at, status)
         VALUES ($1, 'RBAC Test IPO', $2, 10000, 1000, now() - interval '1 hour', now() + interval '5 days', 'under_review')
         RETURNING id`,
        [companyId, `RBC${randomUUID().replace(/-/g, '').slice(0, 7)}`],
      )
    ).rows[0];
    const ipoId = ipoRow!.id;

    // Unauthenticated -> 401
    const unauthApprove = await request(ctx.app).post(`/admin/ipos/${ipoId}/approve`);
    expect(unauthApprove.status).toBe(401);

    const unauthOpen = await request(ctx.app).post(`/admin/ipos/${ipoId}/open`);
    expect(unauthOpen.status).toBe(401);

    // Non-admin roles -> 403
    for (const u of [investor, companyRep, broker]) {
      const resApprove = await request(ctx.app)
        .post(`/admin/ipos/${ipoId}/approve`)
        .set(bearer(u.token))
        .send({ notes: 'Unauthorized attempt' });
      expect(resApprove.status).toBe(403);

      const resOpen = await request(ctx.app)
        .post(`/admin/ipos/${ipoId}/open`)
        .set(bearer(u.token))
        .send({ reason: 'Unauthorized attempt' });
      expect(resOpen.status).toBe(403);
    }
  });
});
