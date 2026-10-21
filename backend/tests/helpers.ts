import 'dotenv/config';
import { randomUUID } from 'node:crypto';
import bcrypt from 'bcryptjs';
import type { Express } from 'express';
import { createApp } from '../src/app.js';
import { type Env, parseEnv } from '../src/config/env.js';
import { createDb, type Db } from '../src/db/pool.js';
import { signAccessToken } from '../src/http/auth.js';
import type { Role } from '../src/http/types.js';
import { createLogger } from '../src/lib/logger.js';
import type { IpoStatus } from '../src/modules/ipos/ipos.service.js';
import { postLedgerEntry } from '../src/modules/wallet/ledger.js';

// Test-only value. Not a secret: it only signs tokens for the throw-away test database.
export const TEST_JWT_SECRET = 'test-only-jwt-signing-value-0123456789-abcdef';
export const TEST_PASSWORD = 'correct-horse-battery';

export function testDatabaseUrl(): string {
  const url = process.env.TEST_DATABASE_URL;
  if (!url) throw new Error('TEST_DATABASE_URL is not set');
  return url;
}

export function testEnv(overrides: Record<string, string> = {}): Env {
  return parseEnv({
    NODE_ENV: 'test',
    DATABASE_URL: testDatabaseUrl(),
    JWT_ACCESS_SECRET: TEST_JWT_SECRET,
    BCRYPT_COST: '4', // fast hashing in tests only
    ENABLE_TEST_FUNDS: 'true',
    AUTH_RATE_LIMIT_MAX: '10000',
    LOG_LEVEL: 'silent',
    ...overrides,
  });
}

export interface TestCtx {
  app: Express;
  db: Db;
  env: Env;
  close: () => Promise<void>;
}

export function buildApp(overrides: Record<string, string> = {}): TestCtx {
  const env = testEnv(overrides);
  const db = createDb(env.DATABASE_URL);
  const app = createApp({ env, db, logger: createLogger('silent') });
  return { app, db, env, close: () => db.end() };
}

export interface TestUser {
  id: string;
  email: string;
  role: Role;
  token: string;
}

/** Insert a user (and an empty wallet for investors) directly, bypassing the API. */
export async function createUser(
  ctx: Pick<TestCtx, 'db' | 'env'>,
  role: Role,
  opts: { suspended?: boolean } = {},
): Promise<TestUser> {
  const email = `${role}-${randomUUID()}@example.test`;
  const hash = await bcrypt.hash(TEST_PASSWORD, 4);
  const { rows } = await ctx.db.query<{ id: string }>(
    `INSERT INTO users (email, password_hash, full_name, role, account_status)
     VALUES ($1, $2, $3, $4, $5) RETURNING id`,
    [email, hash, `Test ${role}`, role, opts.suspended ? 'suspended' : 'active'],
  );
  const id = rows[0]?.id;
  if (!id) throw new Error('user insert failed');
  if (role === 'investor') {
    await ctx.db.query('INSERT INTO wallets (user_id) VALUES ($1)', [id]);
  }
  return { id, email, role, token: signAccessToken(ctx.env, id).token };
}

export async function walletIdOf(db: Db, userId: string): Promise<string> {
  const { rows } = await db.query<{ id: string }>('SELECT id FROM wallets WHERE user_id = $1', [
    userId,
  ]);
  const id = rows[0]?.id;
  if (!id) throw new Error('wallet not found');
  return id;
}

/** Credit simulated funds through the ledger (the only way balances change). */
export async function fundWallet(db: Db, userId: string, amountMinor: number): Promise<string> {
  const walletId = await walletIdOf(db, userId);
  await postLedgerEntry(db, {
    walletId,
    entryType: 'test_fund_credit',
    availableDeltaMinor: amountMinor,
    reservedDeltaMinor: 0,
    idempotencyKey: `fund-${randomUUID()}`,
    initiatedByType: 'system',
  });
  return walletId;
}

/** Create an approved company owned by `ownerId` plus one IPO per requested status. */
export async function createCompanyWithIpos(
  db: Db,
  ownerId: string,
  statuses: IpoStatus[],
): Promise<{ companyId: string; ipos: Record<string, string> }> {
  const company = (
    await db.query<{ id: string }>(
      `INSERT INTO companies (owner_user_id, legal_name, registration_number, onboarding_status)
       VALUES ($1, $2, $3, 'approved') RETURNING id`,
      [ownerId, `Test Co ${randomUUID().slice(0, 8)}`, `REG-${randomUUID()}`],
    )
  ).rows[0];
  if (!company) throw new Error('company insert failed');

  const ipos: Record<string, string> = {};
  for (const status of statuses) {
    const row = (
      await db.query<{ id: string }>(
        `INSERT INTO ipos (company_id, title, symbol, price_per_share_minor, total_shares,
                           opens_at, closes_at, status)
         VALUES ($1, $2, $3, 10000, 1000, now() - interval '1 day', now() + interval '5 days', $4)
         RETURNING id`,
        [company.id, `Test IPO ${status}`, `T${randomUUID().replace(/-/g, '').slice(0, 10)}`, status],
      )
    ).rows[0];
    if (!row) throw new Error('ipo insert failed');
    ipos[status] = row.id;
  }
  return { companyId: company.id, ipos };
}

export const bearer = (token: string): { Authorization: string } => ({
  Authorization: `Bearer ${token}`,
});
