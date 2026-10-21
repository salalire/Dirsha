import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

/**
 * Minimal, repeatable SQL migration runner.
 *
 * - Migrations are plain `.sql` files in /migrations, applied in filename order.
 * - Each file runs in its own transaction together with its bookkeeping row.
 * - Applied files are tracked in `schema_migrations` with a checksum; editing an
 *   already-applied migration is refused (write a new migration instead).
 * - A PostgreSQL advisory lock prevents two runners migrating at the same time.
 */
const MIGRATIONS_DIR = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '../../migrations',
);
const LOCK_KEY = 872_345_001; // arbitrary constant, unique to this app

export interface MigrationFile {
  name: string;
  sql: string;
  checksum: string;
}

export async function loadMigrationFiles(dir = MIGRATIONS_DIR): Promise<MigrationFile[]> {
  const names = (await readdir(dir)).filter((f) => /^\d{4}_.+\.sql$/.test(f)).sort();
  const files: MigrationFile[] = [];
  for (const name of names) {
    const sql = await readFile(path.join(dir, name), 'utf8');
    files.push({ name, sql, checksum: createHash('sha256').update(sql).digest('hex') });
  }
  return files;
}

export interface MigrationStatus {
  name: string;
  applied: boolean;
  appliedAt: Date | null;
}

async function ensureTable(client: pg.Client): Promise<void> {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      name        TEXT PRIMARY KEY,
      checksum    TEXT NOT NULL,
      applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
    )`);
}

/** Apply all pending migrations. Returns the names applied in this run. */
export async function migrateUp(databaseUrl: string, dir = MIGRATIONS_DIR): Promise<string[]> {
  const client = new pg.Client({ connectionString: databaseUrl });
  await client.connect();
  const applied: string[] = [];
  try {
    await client.query('SELECT pg_advisory_lock($1)', [LOCK_KEY]);
    await ensureTable(client);

    const existing = new Map<string, string>(
      (await client.query<{ name: string; checksum: string }>(
        'SELECT name, checksum FROM schema_migrations',
      )).rows.map((r) => [r.name, r.checksum]),
    );

    for (const file of await loadMigrationFiles(dir)) {
      const recorded = existing.get(file.name);
      if (recorded !== undefined) {
        if (recorded !== file.checksum) {
          throw new Error(
            `Migration ${file.name} was modified after being applied. ` +
              'Create a new migration instead of editing an applied one.',
          );
        }
        continue;
      }
      try {
        await client.query('BEGIN');
        await client.query(file.sql);
        await client.query('INSERT INTO schema_migrations (name, checksum) VALUES ($1, $2)', [
          file.name,
          file.checksum,
        ]);
        await client.query('COMMIT');
        applied.push(file.name);
      } catch (err) {
        await client.query('ROLLBACK');
        throw new Error(
          `Migration ${file.name} failed and was rolled back: ${(err as Error).message}`,
          { cause: err },
        );
      }
    }
    return applied;
  } finally {
    try {
      await client.query('SELECT pg_advisory_unlock($1)', [LOCK_KEY]);
    } catch {
      /* connection closing releases the lock anyway */
    }
    await client.end();
  }
}

export async function migrationStatus(
  databaseUrl: string,
  dir = MIGRATIONS_DIR,
): Promise<MigrationStatus[]> {
  const client = new pg.Client({ connectionString: databaseUrl });
  await client.connect();
  try {
    await ensureTable(client);
    const rows = (
      await client.query<{ name: string; applied_at: Date }>(
        'SELECT name, applied_at FROM schema_migrations',
      )
    ).rows;
    const done = new Map(rows.map((r) => [r.name, r.applied_at]));
    return (await loadMigrationFiles(dir)).map((f) => ({
      name: f.name,
      applied: done.has(f.name),
      appliedAt: done.get(f.name) ?? null,
    }));
  } finally {
    await client.end();
  }
}

/**
 * DEV/TEST ONLY: drop everything in the public schema and re-apply all migrations.
 * Callers must guard against production use (the CLI does).
 */
export async function resetDatabase(databaseUrl: string, dir = MIGRATIONS_DIR): Promise<string[]> {
  const client = new pg.Client({ connectionString: databaseUrl });
  await client.connect();
  try {
    await client.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');
  } finally {
    await client.end();
  }
  return migrateUp(databaseUrl, dir);
}
