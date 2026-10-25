import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { createDb } from './pool.js';
import { applyLedgerEntry } from '../modules/wallet/ledger.js';

/**
 * DEV/TEST ONLY seed: clearly-labelled fake data so Members 1 and 3 can exercise the API.
 * - Refuses to run when NODE_ENV=production.
 * - The password for every seeded account comes from the SEED_PASSWORD environment
 *   variable; no password is stored in the repository.
 * - Safe to run repeatedly (everything is keyed on email / symbol).
 *
 *   SEED_PASSWORD='choose-a-local-password' npm run seed
 */
const SEED_USERS = [
  { email: 'admin@dirsha.test', name: 'Test Admin', role: 'admin' },
  { email: 'investor@dirsha.test', name: 'Test Investor', role: 'investor' },
  { email: 'investor2@dirsha.test', name: 'Second Test Investor', role: 'investor' },
  { email: 'company@dirsha.test', name: 'Test Company Rep', role: 'company_rep' },
  { email: 'broker@dirsha.test', name: 'Test Broker', role: 'broker' },
] as const;

const DAY_MS = 86_400_000;

async function main(): Promise<void> {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Refusing to seed when NODE_ENV=production');
  }
  const databaseUrl = process.env.DATABASE_URL;
  const password = process.env.SEED_PASSWORD;
  if (!databaseUrl) throw new Error('DATABASE_URL is not set (see .env.example)');
  if (!password || password.length < 8) {
    throw new Error('Set SEED_PASSWORD to a local password of at least 8 characters');
  }

  const db = createDb(databaseUrl);
  try {
    const hash = await bcrypt.hash(password, 10);
    const ids = new Map<string, string>();

    await db.tx(async (client) => {
      for (const u of SEED_USERS) {
        const { rows } = await client.query<{ id: string }>(
          `INSERT INTO users (email, password_hash, full_name, role, verification_status)
           VALUES ($1, $2, $3, $4, 'verified')
           ON CONFLICT (lower(email)) DO UPDATE SET full_name = EXCLUDED.full_name, password_hash = EXCLUDED.password_hash
           RETURNING id`,
          [u.email, hash, u.name, u.role],
        );
        const id = rows[0]?.id;
        if (!id) throw new Error('seed user insert returned no row');
        ids.set(u.email, id);
        if (u.role === 'investor') {
          await client.query(
            'INSERT INTO wallets (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING',
            [id],
          );
        }
      }

      const companyOwner = ids.get('company@dirsha.test');
      const adminId = ids.get('admin@dirsha.test');
      const brokerOwner = ids.get('broker@dirsha.test');
      const investorId = ids.get('investor@dirsha.test');
      const investor2Id = ids.get('investor2@dirsha.test');
      if (!companyOwner || !adminId) throw new Error('seed accounts missing');

      const company = (
        await client.query<{ id: string }>(
          `INSERT INTO companies
             (owner_user_id, legal_name, registration_number, description,
              onboarding_status, reviewed_by, reviewed_at)
           VALUES ($1, 'Demo Holdings PLC (TEST DATA)', 'TEST-REG-0001',
                   'Fictional company for development. Not a real offering.',
                   'approved', $2, now())
           ON CONFLICT (owner_user_id) DO UPDATE SET legal_name = EXCLUDED.legal_name, onboarding_status = 'approved'
           RETURNING id`,
          [companyOwner, adminId],
        )
      ).rows[0];
      if (!company) throw new Error('seed company insert returned no row');

      // Seed approved broker for broker@dirsha.test
      let brokerRecordId: string | null = null;
      if (brokerOwner) {
        const brk = await client.query<{ id: string }>(
          `INSERT INTO brokers
             (owner_user_id, legal_name, license_number, license_category,
              licensing_authority, license_expiry_date, business_address, business_email, business_phone,
              onboarding_status, reviewed_by, reviewed_at)
           VALUES ($1, 'Ethio Capital Securities S.C.', 'LIC-DIRSHA-001', 'broker_dealer',
                   'Ethiopian Capital Market Authority (ECMA)', '2030-01-01',
                   'Bole Sub-City, Addis Ababa', 'broker@dirsha.test', '+251 911 223 344',
                   'approved', $2, now())
           ON CONFLICT (owner_user_id) DO UPDATE SET legal_name = EXCLUDED.legal_name, onboarding_status = 'approved'
           RETURNING id`,
          [brokerOwner, adminId],
        );
        brokerRecordId = brk.rows[0]?.id ?? null;
      }

      const now = Date.now();
      const ipos = [
        { symbol: 'TESTA', title: 'TEST IPO A (open for subscription)', status: 'open', opens: -1, closes: 14 },
        { symbol: 'TESTB', title: 'TEST IPO B (open for subscription)', status: 'open', opens: -2, closes: 7 },
        { symbol: 'TESTC', title: 'TEST IPO C (listed for trading)', status: 'listed', opens: -30, closes: -5 },
        { symbol: 'TESTD', title: 'TEST IPO D (approved upcoming)', status: 'approved', opens: 2, closes: 12 },
        { symbol: 'TESTE', title: 'TEST IPO E (draft)', status: 'draft', opens: 10, closes: 20 },
      ];
      const ipoIds = new Map<string, string>();
      for (const i of ipos) {
        const row = (
          await client.query<{ id: string }>(
            `INSERT INTO ipos
               (company_id, title, symbol, description, price_per_share_minor, total_shares,
                min_shares_per_subscription, max_shares_per_subscription, opens_at, closes_at, status)
             VALUES ($1, $2, $3, 'Fictional test security. Simulated funds only.',
                     10000, 100000, 10, 5000, $4, $5, $6)
             ON CONFLICT (symbol) DO UPDATE SET
               opens_at = EXCLUDED.opens_at, closes_at = EXCLUDED.closes_at, status = EXCLUDED.status, title = EXCLUDED.title
             RETURNING id`,
            [
              company.id,
              i.title,
              i.symbol,
              new Date(now + i.opens * DAY_MS),
              new Date(now + i.closes * DAY_MS),
              i.status,
            ],
          )
        ).rows[0];
        if (row) {
          ipoIds.set(i.symbol, row.id);
          await client.query(
            `INSERT INTO ipo_status_history (ipo_id, from_status, to_status, changed_by, reason)
             VALUES ($1, NULL, $2, $3, 'seed data')`,
            [row.id, i.status, adminId],
          );
        }
      }

      // Fund investor@dirsha.test with 50,000 ETB (5,000,000 santim)
      if (investorId) {
        const w = (
          await client.query<{ id: string }>('SELECT id FROM wallets WHERE user_id = $1', [
            investorId,
          ])
        ).rows[0];
        if (w) {
          try {
            await applyLedgerEntry(client, {
              walletId: w.id,
              entryType: 'test_fund_credit',
              availableDeltaMinor: 5_000_000,
              reservedDeltaMinor: 0,
              idempotencyKey: 'seed-initial-funds-v2',
              initiatedByType: 'system',
              description: 'Seed: simulated test funds for primary investor',
            });
          } catch {
            // Already funded
          }
        }
      }

      // Fund investor2@dirsha.test with 50,000 ETB (5,000,000 santim)
      if (investor2Id) {
        const w2 = (
          await client.query<{ id: string }>('SELECT id FROM wallets WHERE user_id = $1', [
            investor2Id,
          ])
        ).rows[0];
        if (w2) {
          try {
            await applyLedgerEntry(client, {
              walletId: w2.id,
              entryType: 'test_fund_credit',
              availableDeltaMinor: 5_000_000,
              reservedDeltaMinor: 0,
              idempotencyKey: 'seed-investor2-funds',
              initiatedByType: 'system',
              description: 'Seed: simulated test funds for second investor',
            });
          } catch {
            // Already funded
          }
        }
      }

      // Seed share holdings for secondary trading:
      // investor2 owns 1,000 shares of TESTC (listed) and 500 shares of TESTA
      const testCId = ipoIds.get('TESTC');
      const testAId = ipoIds.get('TESTA');
      if (investor2Id && testCId) {
        await client.query(
          `INSERT INTO share_holdings (investor_id, ipo_id, quantity, reserved_quantity)
           VALUES ($1, $2, 1000, 0)
           ON CONFLICT (investor_id, ipo_id) DO UPDATE SET quantity = 1000, reserved_quantity = 0`,
          [investor2Id, testCId],
        );
      }
      if (investorId && testAId) {
        await client.query(
          `INSERT INTO share_holdings (investor_id, ipo_id, quantity, reserved_quantity)
           VALUES ($1, $2, 200, 0)
           ON CONFLICT (investor_id, ipo_id) DO UPDATE SET quantity = 200, reserved_quantity = 0`,
          [investorId, testAId],
        );
      }

      // Seed active broker-client relationship between broker and investor
      if (brokerRecordId && investorId) {
        await client.query(
          `INSERT INTO broker_client_relationships (broker_id, investor_id, relationship_type, status, requested_by)
           VALUES ($1, $2, 'advisory', 'active', 'broker')
           ON CONFLICT (broker_id, investor_id) DO UPDATE SET status = 'active'`,
          [brokerRecordId, investorId],
        );
      }
    });

    process.stdout.write(
      'Seed complete: 5 test accounts (*@dirsha.test with password), 1 company, 1 broker, 5 test IPOs,\n' +
        'simulated funds for investors, share holdings, and active broker relationship.\n',
    );
  } finally {
    await db.end();
  }
}

main().catch((err: unknown) => {
  process.stderr.write(`${(err as Error).message}\n`);
  process.exit(1);
});
