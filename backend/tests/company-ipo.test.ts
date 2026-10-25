import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { bearer, buildApp, createUser, type TestUser } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

let admin: TestUser;
let investor: TestUser;
let unapprovedRep: TestUser;
let approvedRep: TestUser;
let otherApprovedRep: TestUser;
let approvedCompanyId: string;
let _otherCompanyId: string;

beforeAll(async () => {
  [admin, investor, unapprovedRep, approvedRep, otherApprovedRep] = await Promise.all([
    createUser(ctx, 'admin'),
    createUser(ctx, 'investor'),
    createUser(ctx, 'company_rep'),
    createUser(ctx, 'company_rep'),
    createUser(ctx, 'company_rep'),
  ]);

  // Unapproved company (status: draft)
  await ctx.db.query(
    `INSERT INTO companies (owner_user_id, legal_name, registration_number, onboarding_status)
     VALUES ($1, 'Pending Tech PLC', 'REG-PEND-01', 'draft')`,
    [unapprovedRep.id],
  );

  // Approved company 1
  const comp1 = await ctx.db.query<{ id: string }>(
    `INSERT INTO companies (owner_user_id, legal_name, registration_number, onboarding_status)
     VALUES ($1, 'Abyssinia Cloud Tech S.C.', 'REG-ABYS-01', 'approved')
     RETURNING id`,
    [approvedRep.id],
  );
  approvedCompanyId = comp1.rows[0]!.id;

  // Approved company 2
  const comp2 = await ctx.db.query<{ id: string }>(
    `INSERT INTO companies (owner_user_id, legal_name, registration_number, onboarding_status)
     VALUES ($1, 'Horn Financial S.C.', 'REG-HORN-01', 'approved')
     RETURNING id`,
    [otherApprovedRep.id],
  );
  _otherCompanyId = comp2.rows[0]!.id;
});

describe('Company IPO Creation and Management Workflow (Decision 2)', () => {
  it('forbids investor from creating an IPO', async () => {
    const res = await request(ctx.app)
      .post('/ipos')
      .set(bearer(investor.token))
      .send({
        title: 'Investor IPO',
        symbol: 'INVST',
        price_per_share_minor: 10000,
        total_shares: 100000,
        opens_at: new Date(Date.now() + 86400000).toISOString(),
        closes_at: new Date(Date.now() + 86400000 * 10).toISOString(),
      });

    expect(res.status).toBe(403);
  });

  it('rejects IPO creation when company onboarding is not approved', async () => {
    const res = await request(ctx.app)
      .post('/ipos')
      .set(bearer(unapprovedRep.token))
      .send({
        title: 'Pending Offering',
        symbol: 'PEND',
        price_per_share_minor: 5000,
        total_shares: 50000,
        opens_at: new Date(Date.now() + 86400000).toISOString(),
        closes_at: new Date(Date.now() + 86400000 * 5).toISOString(),
      });

    expect(res.status).toBe(403);
    expect(res.body.error?.code).toBe('FORBIDDEN');
    expect(res.body.error?.message).toContain('approved');
  });

  it('validates dates: closes_at must be strictly after opens_at', async () => {
    const now = Date.now();
    const res = await request(ctx.app)
      .post('/ipos')
      .set(bearer(approvedRep.token))
      .send({
        title: 'Invalid Date Offering',
        symbol: 'INVD',
        price_per_share_minor: 5000,
        total_shares: 50000,
        opens_at: new Date(now + 86400000 * 5).toISOString(),
        closes_at: new Date(now + 86400000 * 2).toISOString(), // earlier than opens_at
      });

    expect(res.status).toBe(400);
  });

  let createdIpoId: string;

  it('allows approved company rep to create an IPO offering draft', async () => {
    const now = Date.now();
    const opensAt = new Date(now + 86400000 * 2).toISOString();
    const closesAt = new Date(now + 86400000 * 16).toISOString();

    const res = await request(ctx.app)
      .post('/ipos')
      .set(bearer(approvedRep.token))
      .send({
        title: 'Abyssinia Cloud Series A',
        symbol: 'ABYS',
        description: 'First public digital offering for Abyssinia Cloud Tech.',
        price_per_share_minor: 7500, // 75.00 ETB
        total_shares: 500000,
        min_shares_per_subscription: 10,
        max_shares_per_subscription: 5000,
        opens_at: opensAt,
        closes_at: closesAt,
      });

    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({
      title: 'Abyssinia Cloud Series A',
      symbol: 'ABYS',
      company_id: approvedCompanyId,
      status: 'draft',
      price_per_share_minor: 7500,
      total_shares: 500000,
      min_shares_per_subscription: 10,
      max_shares_per_subscription: 5000,
    });
    createdIpoId = res.body.data.id;
  });

  it('rejects duplicate symbol', async () => {
    const now = Date.now();
    const res = await request(ctx.app)
      .post('/ipos')
      .set(bearer(approvedRep.token))
      .send({
        title: 'Another Offering Same Symbol',
        symbol: 'ABYS', // duplicate
        price_per_share_minor: 7500,
        total_shares: 100000,
        opens_at: new Date(now + 86400000).toISOString(),
        closes_at: new Date(now + 86400000 * 10).toISOString(),
      });

    expect(res.status).toBe(409);
    expect(res.body.error?.code).toBe('CONFLICT');
    expect(res.body.error?.message).toContain('ABYS');
  });

  it('allows company rep to update draft offering terms', async () => {
    const res = await request(ctx.app)
      .put(`/ipos/${createdIpoId}`)
      .set(bearer(approvedRep.token))
      .send({
        title: 'Abyssinia Cloud Primary Offering',
        price_per_share_minor: 8000, // update to 80.00 ETB
      });

    expect(res.status).toBe(200);
    expect(res.body.data.title).toBe('Abyssinia Cloud Primary Offering');
    expect(res.body.data.price_per_share_minor).toBe(8000);
  });

  it('forbids other company rep from modifying the draft', async () => {
    const res = await request(ctx.app)
      .put(`/ipos/${createdIpoId}`)
      .set(bearer(otherApprovedRep.token))
      .send({
        title: 'Hacked Title',
      });

    expect(res.status).toBe(403);
  });

  let uploadedDocId: string;

  it('allows company rep to upload offering documents', async () => {
    const dummyPdfContent = Buffer.from('%PDF-1.4 simulated offering prospectus').toString('base64');
    const res = await request(ctx.app)
      .post(`/ipos/${createdIpoId}/documents`)
      .set(bearer(approvedRep.token))
      .send({
        document_type: 'prospectus',
        file_name: 'Abyssinia_Cloud_Prospectus_2026.pdf',
        mime_type: 'application/pdf',
        content: dummyPdfContent,
      });

    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({
      document_type: 'prospectus',
      file_name: 'Abyssinia_Cloud_Prospectus_2026.pdf',
      review_status: 'pending',
    });
    uploadedDocId = res.body.data.id;
  });

  it('lists uploaded offering documents for authorized rep', async () => {
    const res = await request(ctx.app)
      .get(`/ipos/${createdIpoId}/documents`)
      .set(bearer(approvedRep.token));

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].id).toBe(uploadedDocId);
  });

  it('allows company rep to submit draft IPO for administrative review', async () => {
    const res = await request(ctx.app)
      .post(`/ipos/${createdIpoId}/submit`)
      .set(bearer(approvedRep.token))
      .send({
        notes: 'Submitted for ECMA and exchange compliance verification.',
      });

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('submitted');
  });

  it('prevents modifying an IPO once submitted', async () => {
    const res = await request(ctx.app)
      .put(`/ipos/${createdIpoId}`)
      .set(bearer(approvedRep.token))
      .send({
        title: 'Cannot Edit Submitted Offering',
      });

    expect(res.status).toBe(409);
    expect(res.body.error?.code).toBe('CONFLICT');
  });

  it('lists company offerings on GET /ipos/my-offerings', async () => {
    const res = await request(ctx.app)
      .get('/ipos/my-offerings')
      .set(bearer(approvedRep.token));

    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    const item = res.body.data.find((o: { id: string }) => o.id === createdIpoId);
    expect(item).toBeDefined();
    expect(item.symbol).toBe('ABYS');
    expect(item.status).toBe('submitted');
    expect(item.documents_count).toBe(1);
  });

  it('admin can review, approve the submitted IPO, and view its documents', async () => {
    // 1. Admin gets details
    const detailRes = await request(ctx.app)
      .get(`/ipos/${createdIpoId}`)
      .set(bearer(admin.token));

    expect(detailRes.status).toBe(200);
    expect(detailRes.body.data.status).toBe('submitted');
    expect(detailRes.body.data.documents).toHaveLength(1);

    // 2. Admin approves IPO
    const approveRes = await request(ctx.app)
      .post(`/admin/ipos/${createdIpoId}/approve`)
      .set(bearer(admin.token))
      .send({
        notes: 'Compliance criteria met. Approved for offering window.',
      });

    expect(approveRes.status).toBe(200);
    expect(approveRes.body.data.status).toBe('approved');

    // 3. Status history records transitions
    const historyRes = await request(ctx.app)
      .get(`/ipos/${createdIpoId}/history`)
      .set(bearer(approvedRep.token));

    expect(historyRes.status).toBe(200);
    expect(historyRes.body.data.length).toBeGreaterThanOrEqual(3); // draft -> submitted -> approved
    const lastEvent = historyRes.body.data[historyRes.body.data.length - 1];
    expect(lastEvent.to_status).toBe('approved');
  });
});
