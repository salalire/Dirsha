import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { bearer, buildApp, createCompanyWithIpos, createUser, type TestUser } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

let investor: TestUser;
let broker: TestUser;
let admin: TestUser;
let repA: TestUser;
let repB: TestUser;
let a: Record<string, string>; // company A's IPOs by status
let b: Record<string, string>; // company B's IPOs by status

beforeAll(async () => {
  [investor, broker, admin, repA, repB] = await Promise.all([
    createUser(ctx, 'investor'),
    createUser(ctx, 'broker'),
    createUser(ctx, 'admin'),
    createUser(ctx, 'company_rep'),
    createUser(ctx, 'company_rep'),
  ]);
  a = (await createCompanyWithIpos(ctx.db, repA.id, ['draft', 'under_review', 'open', 'listed'])).ipos;
  b = (await createCompanyWithIpos(ctx.db, repB.id, ['draft', 'open'])).ipos;
});

const ids = (body: { data: { id: string }[] }): string[] => body.data.map((i) => i.id);
const list = (user: TestUser, query = 'page_size=100') =>
  request(ctx.app).get(`/ipos?${query}`).set(bearer(user.token));
const detail = (user: TestUser, id: string) =>
  request(ctx.app).get(`/ipos/${id}`).set(bearer(user.token));

describe('GET /ipos visibility (FR-IPO-07, FR-ONB-06)', () => {
  it('investors and brokers see only public statuses', async () => {
    for (const user of [investor, broker]) {
      const res = await list(user);
      expect(res.status).toBe(200);
      const got = ids(res.body);
      expect(got).toContain(a.open);
      expect(got).toContain(a.listed);
      expect(got).toContain(b.open);
      expect(got).not.toContain(a.draft);
      expect(got).not.toContain(a.under_review);
      expect(got).not.toContain(b.draft);
    }
  });

  it("a company rep sees public IPOs plus their own company's private ones only", async () => {
    const res = await list(repA);
    const got = ids(res.body);
    expect(got).toEqual(expect.arrayContaining([a.draft, a.under_review, a.open, a.listed, b.open]));
    expect(got).not.toContain(b.draft); // another company's private IPO
  });

  it('admins see every IPO', async () => {
    const got = ids((await list(admin)).body);
    expect(got).toEqual(expect.arrayContaining([a.draft, a.under_review, a.open, b.draft, b.open]));
  });

  it('filters by status without widening visibility', async () => {
    const asInvestor = await list(investor, 'status=draft&page_size=100');
    expect(asInvestor.status).toBe(200);
    expect(asInvestor.body.data).toEqual([]);

    const asAdmin = await list(admin, 'status=draft&page_size=100');
    expect(ids(asAdmin.body)).toEqual(expect.arrayContaining([a.draft, b.draft]));
    expect(asAdmin.body.data.every((i: { status: string }) => i.status === 'draft')).toBe(true);
  });

  it('paginates', async () => {
    const res = await list(admin, 'page=1&page_size=2');
    expect(res.body.data.length).toBeLessThanOrEqual(2);
    expect(res.body.pagination).toMatchObject({ page: 1, page_size: 2 });
    expect(res.body.pagination.total).toBeGreaterThanOrEqual(6);
    const beyond = await list(admin, 'page=9999&page_size=2');
    expect(beyond.body.data).toEqual([]);
  });

  it('validates query parameters', async () => {
    for (const q of ['status=bogus', 'page=0', 'page_size=101', 'page_size=abc']) {
      const res = await list(investor, q);
      expect(res.status, q).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    }
  });
});

describe('GET /ipos/:id', () => {
  it('returns amounts as integer minor units with an explicit currency', async () => {
    const res = await detail(investor, a.open as string);
    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({
      id: a.open,
      status: 'open',
      currency: 'ETB',
      price_per_share_minor: 10000,
      total_shares: 1000,
      min_shares_per_subscription: 1,
      max_shares_per_subscription: null,
    });
    expect(Number.isInteger(res.body.data.price_per_share_minor)).toBe(true);
    expect(typeof res.body.data.company_name).toBe('string');
    expect(new Date(res.body.data.opens_at).toString()).not.toBe('Invalid Date');
  });

  it('hides private IPOs from outsiders with the same 404 as a missing IPO', async () => {
    const hidden = await detail(investor, a.draft as string);
    const missing = await detail(investor, randomUUID());
    const otherCompany = await detail(repB, a.draft as string);
    for (const res of [hidden, missing, otherCompany]) {
      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
      expect(res.body.error.message).toBe('IPO not found');
    }
  });

  it('lets the owning company and admins read a private IPO', async () => {
    expect((await detail(repA, a.draft as string)).status).toBe(200);
    expect((await detail(admin, a.draft as string)).status).toBe(200);
  });

  it('rejects a malformed id with a validation error, not a database error', async () => {
    const res = await request(ctx.app).get('/ipos/not-a-uuid').set(bearer(investor.token));
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('is read-only in Phase 1: writes are not routed', async () => {
    const res = await request(ctx.app)
      .post('/ipos')
      .set(bearer(admin.token))
      .send({ title: 'x' });
    expect(res.status).toBe(404);
    expect((await request(ctx.app).delete(`/ipos/${a.open}`).set(bearer(admin.token))).status).toBe(404);
  });
});
