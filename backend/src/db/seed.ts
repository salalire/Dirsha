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
           ON CONFLICT (lower(email)) DO UPDATE SET full_name = EXCLUDED.full_name
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
      if (!companyOwner || !adminId) throw new Error('seed accounts missing');

      const company = (
        await client.query<{ id: string }>(
          `INSERT INTO companies
             (owner_user_id, legal_name, registration_number, description,
              onboarding_status, reviewed_by, reviewed_at)
           VALUES ($1, 'Demo Holdings PLC (TEST DATA)', 'TEST-REG-0001',
                   'Fictional company for development. Not a real offering.',
                   'approved', $2, now())
           ON CONFLICT (owner_user_id) DO UPDATE SET legal_name = EXCLUDED.legal_name
           RETURNING id`,
          [companyOwner, adminId],
        )
      ).rows[0];
      if (!company) throw new Error('seed company insert returned no row');

      const now = Date.now();
      const ipos = [
        { symbol: 'TESTA', title: 'TEST IPO A (open)', status: 'open', opens: -1, closes: 6 },
        { symbol: 'TESTB', title: 'TEST IPO B (open)', status: 'open', opens: -2, closes: 3 },
        { symbol: 'TESTC', title: 'TEST IPO C (listed)', status: 'listed', opens: -30, closes: -20 },
        { symbol: 'TESTD', title: 'TEST IPO D (under review)', status: 'under_review', opens: 5, closes: 12 },
        { symbol: 'TESTE', title: 'TEST IPO E (draft)', status: 'draft', opens: 10, closes: 17 },
      ];
      for (const i of ipos) {
        const row = (
          await client.query<{ id: string; inserted: boolean }>(
            `INSERT INTO ipos
               (company_id, title, symbol, description, price_per_share_minor, total_shares,
                min_shares_per_subscription, max_shares_per_subscription, opens_at, closes_at, status)
             VALUES ($1, $2, $3, 'Fictional test security. Simulated funds only.',
                     10000, 100000, 10, 5000, $4, $5, $6)
             ON CONFLICT (symbol) DO NOTHING
             RETURNING id, true AS inserted`,
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
          await client.query(
            `INSERT INTO ipo_status_history (ipo_id, from_status, to_status, changed_by, reason)
             VALUES ($1, NULL, $2, $3, 'seed data')`,
            [row.id, i.status, adminId],
          );
        }
      }

      // 10,000 ETB of SIMULATED funds for the primary test investor, via the ledger,
      // once (idempotency key makes re-running the seed a no-op).
      const investorId = ids.get('investor@dirsha.test');
      if (investorId) {
        const w = (
          await client.query<{ id: string }>('SELECT id FROM wallets WHERE user_id = $1', [
            investorId,
          ])
        ).rows[0];
        if (w) {
          await applyLedgerEntry(client, {
            walletId: w.id,
            entryType: 'test_fund_credit',
            availableDeltaMinor: 1_000_000,
            reservedDeltaMinor: 0,
            idempotencyKey: 'seed-initial-funds',
            initiatedByType: 'system',
            description: 'Seed: simulated test funds (not real money)',
          });
        }
      }
    });

    process.stdout.write(
      'Seed complete: 5 test accounts (*@dirsha.test), 1 company, 5 test IPOs,\n' +
        '10,000.00 ETB simulated funds for investor@dirsha.test.\n',
    );
  } finally {
    await db.end();
  }
}

main().catch((err: unknown) => {
  process.stderr.write(`${(err as Error).message}\n`);
  process.exit(1);
});
