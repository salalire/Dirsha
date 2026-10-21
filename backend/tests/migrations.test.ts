import { cp, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { loadMigrationFiles, migrateUp, migrationStatus } from '../src/db/migrate.js';
import { testDatabaseUrl } from './helpers.js';

const MIGRATIONS = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../migrations');

describe('migrations', () => {
  it('were applied from a clean database by global setup and are all recorded', async () => {
    const files = await loadMigrationFiles();
    expect(files.length).toBeGreaterThanOrEqual(4);
    const status = await migrationStatus(testDatabaseUrl());
    expect(status.every((m) => m.applied)).toBe(true);
  });

  it('are repeatable: running again applies nothing', async () => {
    expect(await migrateUp(testDatabaseUrl())).toEqual([]);
  });

  it('refuses to run if an already-applied migration file was edited', async () => {
    const dir = await mkdtemp(path.join(os.tmpdir(), 'dirsha-mig-'));
    try {
      await cp(MIGRATIONS, dir, { recursive: true });
      const first = path.join(dir, '0001_users.sql');
      await writeFile(first, `${await readFile(first, 'utf8')}\n-- tampered`);
      await expect(migrateUp(testDatabaseUrl(), dir)).rejects.toThrow(/modified after being applied/);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });

  it('use exact numeric types for money: no floating point columns anywhere', async () => {
    const files = await loadMigrationFiles();
    const sql = files.map((f) => f.sql).join('\n');
    expect(sql).not.toMatch(/\b(REAL|DOUBLE PRECISION|FLOAT)\b/i);
  });
});
