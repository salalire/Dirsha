import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { bearer, buildApp, createUser, type TestUser } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

let admin: TestUser;
let investor1: TestUser;
let investor2: TestUser;
let unapprovedBrokerUser: TestUser;
let approvedBrokerUser: TestUser;
let otherBrokerUser: TestUser;

let approvedBrokerId: string;
let _otherBrokerId: string;
let testIpoId: string;

beforeAll(async () => {
  [admin, investor1, investor2, unapprovedBrokerUser, approvedBrokerUser, otherBrokerUser] =
    await Promise.all([
      createUser(ctx, 'admin'),
      createUser(ctx, 'investor'),
      createUser(ctx, 'investor'),
      createUser(ctx, 'broker'),
      createUser(ctx, 'broker'),
      createUser(ctx, 'broker'),
    ]);

  // Unapproved broker
  await ctx.db.query(
    `INSERT INTO brokers (owner_user_id, legal_name, license_number, license_category, licensing_authority, license_expiry_date, onboarding_status)
     VALUES ($1, 'Pending Capital Ltd', 'LIC-PEND-01', 'broker_dealer', 'ECMA', '2030-01-01', 'submitted')`,
    [unapprovedBrokerUser.id],
  );

  // Approved broker 1
  const b1 = await ctx.db.query<{ id: string }>(
    `INSERT INTO brokers (owner_user_id, legal_name, license_number, license_category, licensing_authority, license_expiry_date, onboarding_status)
     VALUES ($1, 'Lion Capital Securities S.C.', 'LIC-LION-01', 'broker_dealer', 'ECMA', '2030-01-01', 'approved')
     RETURNING id`,
    [approvedBrokerUser.id],
  );
  approvedBrokerId = b1.rows[0]!.id;

  // Approved broker 2
  const b2 = await ctx.db.query<{ id: string }>(
    `INSERT INTO brokers (owner_user_id, legal_name, license_number, license_category, licensing_authority, license_expiry_date, onboarding_status)
     VALUES ($1, 'Blue Nile Securities S.C.', 'LIC-NILE-01', 'investment_advisor', 'ECMA', '2030-01-01', 'approved')
     RETURNING id`,
    [otherBrokerUser.id],
  );
  _otherBrokerId = b2.rows[0]!.id;

  // Create an active company and an open IPO
  const comp = await ctx.db.query<{ id: string }>(
    `INSERT INTO companies (owner_user_id, legal_name, registration_number, onboarding_status)
     VALUES ($1, 'Addis Pharma S.C.', 'REG-PHARMA-01', 'approved')
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
       $1, 'Addis Pharma IPO', 'ADPH', 5000, 1000000,
       'open', now() - INTERVAL '1 day', now() + INTERVAL '10 days'
     )
     RETURNING id`,
    [companyId],
  );
  testIpoId = ipo.rows[0]!.id;

  // Seed investor1 wallet
  await ctx.db.query(
    `INSERT INTO wallets (user_id, available_minor, reserved_minor, currency)
     VALUES ($1, 2500000, 500000, 'ETB')
     ON CONFLICT (user_id) DO UPDATE SET available_minor = 2500000, reserved_minor = 500000`,
    [investor1.id],
  );

  // Seed investor1 share holding
  await ctx.db.query(
    `INSERT INTO share_holdings (investor_id, ipo_id, quantity, reserved_quantity)
     VALUES ($1, $2, 500, 50)
     ON CONFLICT (investor_id, ipo_id) DO UPDATE SET quantity = 500, reserved_quantity = 50`,
    [investor1.id, testIpoId],
  );
});

describe('Broker Functionality & Client Management (Task D)', () => {
  describe('Profile & Dashboard Access', () => {
    it('forbids investor from accessing broker profile', async () => {
      const res = await request(ctx.app)
        .get('/brokers/me')
        .set(bearer(investor1.token));
      expect(res.status).toBe(403);
    });

    it('returns broker profile for authenticated approved broker', async () => {
      const res = await request(ctx.app)
        .get('/brokers/me')
        .set(bearer(approvedBrokerUser.token));
      expect(res.status).toBe(200);
      expect(res.body.id).toBe(approvedBrokerId);
      expect(res.body.firm_legal_name).toBe('Lion Capital Securities S.C.');
      expect(res.body.onboarding_status).toBe('approved');
    });

    it('returns broker dashboard metrics', async () => {
      const res = await request(ctx.app)
        .get('/brokers/dashboard')
        .set(bearer(approvedBrokerUser.token));
      expect(res.status).toBe(200);
      expect(res.body.broker.id).toBe(approvedBrokerId);
      expect(res.body.metrics).toBeDefined();
      expect(res.body.metrics.total_active_clients).toBe(0);
      expect(res.body.metrics.available_ipos_count).toBeGreaterThanOrEqual(1);
    });

    it('returns available offerings for broker discovery', async () => {
      const res = await request(ctx.app)
        .get('/brokers/ipos')
        .set(bearer(approvedBrokerUser.token));
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
      const found = res.body.data.some((i: { id: string }) => i.id === testIpoId);
      expect(found).toBe(true);
    });
  });

  describe('Client Relationship Lifecycle & Consent', () => {
    let relationshipId: string;

    it('rejects relationship request from unapproved broker', async () => {
      const res = await request(ctx.app)
        .post('/brokers/clients/request')
        .set(bearer(unapprovedBrokerUser.token))
        .send({
          investor_email: investor1.email,
          relationship_type: 'advisory',
          notes: 'Client onboarding request',
        });
      expect(res.status).toBe(403);
    });

    it('returns 404 when requesting relationship with unknown email', async () => {
      const res = await request(ctx.app)
        .post('/brokers/clients/request')
        .set(bearer(approvedBrokerUser.token))
        .send({
          investor_email: 'unknown-user@doesnotexist.et',
          relationship_type: 'advisory',
        });
      expect(res.status).toBe(404);
    });

    it('allows approved broker to request relationship with eligible investor', async () => {
      const res = await request(ctx.app)
        .post('/brokers/clients/request')
        .set(bearer(approvedBrokerUser.token))
        .send({
          investor_email: investor1.email,
          relationship_type: 'advisory',
          notes: 'Portfolio advisory partnership',
        });
      expect(res.status).toBe(201);
      expect(res.body.status).toBe('pending');
      expect(res.body.investor_email).toBe(investor1.email);
      expect(res.body.broker_id).toBe(approvedBrokerId);
      relationshipId = res.body.id;
    });

    it('prevents duplicate relationship requests while pending', async () => {
      const res = await request(ctx.app)
        .post('/brokers/clients/request')
        .set(bearer(approvedBrokerUser.token))
        .send({
          investor_email: investor1.email,
          relationship_type: 'execution_only',
        });
      expect(res.status).toBe(409);
    });

    it('lists client in pending state on broker client roster', async () => {
      const res = await request(ctx.app)
        .get('/brokers/clients?status=pending')
        .set(bearer(approvedBrokerUser.token));
      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
      const match = res.body.data.find((c: { id: string }) => c.id === relationshipId);
      expect(match).toBeDefined();
      expect(match.status).toBe('pending');
    });

    it('DENIES broker access to client private financial details while relationship is pending', async () => {
      const res = await request(ctx.app)
        .get(`/brokers/clients/${investor1.id}`)
        .set(bearer(approvedBrokerUser.token));
      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('Access denied');
    });

    it('investor can view pending broker relationship requests', async () => {
      const res = await request(ctx.app)
        .get('/brokers/relationships/my')
        .set(bearer(investor1.token));
      expect(res.status).toBe(200);
      const reqItem = res.body.data.find((r: { id: string }) => r.id === relationshipId);
      expect(reqItem).toBeDefined();
      expect(reqItem.broker_firm_name).toBe('Lion Capital Securities S.C.');
      expect(reqItem.status).toBe('pending');
    });

    it('forbids another user from responding to investor relationship request', async () => {
      const res = await request(ctx.app)
        .post(`/brokers/relationships/${relationshipId}/respond`)
        .set(bearer(investor2.token))
        .send({ action: 'accept' });
      expect(res.status).toBe(403);
    });

    it('allows investor to accept relationship request', async () => {
      const res = await request(ctx.app)
        .post(`/brokers/relationships/${relationshipId}/respond`)
        .set(bearer(investor1.token))
        .send({ action: 'accept' });
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('active');
      expect(res.body.responded_at).toBeDefined();
    });

    it('GRANTS authorized broker access to client financial details and holdings once active', async () => {
      const res = await request(ctx.app)
        .get(`/brokers/clients/${investor1.id}`)
        .set(bearer(approvedBrokerUser.token));
      expect(res.status).toBe(200);
      expect(res.body.client.id).toBe(investor1.id);
      expect(res.body.wallet.available_minor).toBe(2500000);
      expect(res.body.wallet.reserved_minor).toBe(500000);
      expect(res.body.wallet.total_minor).toBe(3000000);
      expect(res.body.holdings.length).toBe(1);
      expect(res.body.holdings[0].symbol).toBe('ADPH');
      expect(res.body.holdings[0].quantity).toBe(500);
    });

    it('prevents another unauthorized broker from accessing client details', async () => {
      const res = await request(ctx.app)
        .get(`/brokers/clients/${investor1.id}`)
        .set(bearer(otherBrokerUser.token));
      expect(res.status).toBe(404);
    });

    it('allows investor to revoke relationship consent', async () => {
      const res = await request(ctx.app)
        .post(`/brokers/relationships/${relationshipId}/respond`)
        .set(bearer(investor1.token))
        .send({ action: 'revoke' });
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('revoked');
    });

    it('immediately denies broker access to client details after revocation', async () => {
      const res = await request(ctx.app)
        .get(`/brokers/clients/${investor1.id}`)
        .set(bearer(approvedBrokerUser.token));
      expect(res.status).toBe(403);
    });
  });
});
