import 'dotenv/config';
import { createAdminAccount } from '../modules/users/admin-provision.js';
import { createDb } from './pool.js';

/**
 * Create an administrator account.
 *
 *   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='a-long-passphrase' npm run create-admin
 *
 * Credentials come from environment variables so they never appear in the repository.
 * Optional: ADMIN_NAME (default "Administrator").
 */
async function main(): Promise<void> {
  const databaseUrl = process.env.DATABASE_URL;
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;
  if (!databaseUrl) throw new Error('DATABASE_URL is not set (see .env.example)');
  if (!email || !password) throw new Error('Set ADMIN_EMAIL and ADMIN_PASSWORD in the environment');

  const bcryptCost = Number(process.env.BCRYPT_COST ?? 12);
  const db = createDb(databaseUrl);
  try {
    const admin = await createAdminAccount(db, {
      email,
      password,
      fullName: process.env.ADMIN_NAME ?? 'Administrator',
      bcryptCost: Number.isInteger(bcryptCost) && bcryptCost >= 10 ? bcryptCost : 12,
    });
    process.stdout.write(`Admin account created: ${admin.email} (id ${admin.id})\n`);
  } finally {
    await db.end();
  }
}

main().catch((err: unknown) => {
  process.stderr.write(`${(err as Error).message}\n`);
  process.exit(1);
});
