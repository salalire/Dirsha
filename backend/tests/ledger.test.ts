import { randomUUID } from 'node:crypto';
import { afterAll, describe, expect, it } from 'vitest';
import { AppError } from '../src/lib/errors.js';
import { recordAudit } from '../src/modules/audit/audit.service.js';
import { applyLedgerEntry, postLedgerEntry, type LedgerInput } from '../src/modules/wallet/ledger.js';
import { buildApp, createUser, fundWallet } from './helpers.js';

const ctx = buildApp();
afterAll(() => ctx.close());

async function newFundedWallet(amount: number): Promise<string> {
  const u = await createUser(ctx, 'investor');
  return fundWallet(ctx.db, u.id, amount);
}

async function balances(walletId: string): Promise<{ available: number; reserved: number }> {
  const { rows } = await ctx.db.query<{ available_minor: string; reserved_minor: string }>(
    'SELECT available_minor, reserved_minor FROM wallets WHERE id = $1',
    [walletId],
  );
  return { available: Number(rows[0]?.available_minor), reserved: Number(rows[0]?.reserved_minor) };
}

async function entryCount(walletId: string): Promise<number> {
  const { rows } = await ctx.db.query<{ n: number }>(
    'SELECT count(*)::int AS n FROM ledger_entries WHERE wallet_id = $1',
    [walletId],
  );
  return rows[0]?.n ?? -1;
}

async function reconciled(walletId: string): Promise<boolean> {
  const { rows } = await ctx.db.query<{ ok: boolean }>(
    'SELECT ok FROM wallet_reconciliation WHERE wallet_id = $1',
    [walletId],
  );
  return rows[0]?.ok === true;
}

const reserve = (walletId: string, amount: number, idem = `res-${randomUUID()}`): LedgerInput => ({
  walletId,
  entryType: 'subscription_reserve',
  availableDeltaMinor: -amount,
  reservedDeltaMinor: amount,
  referenceType: 'subscription',
  referenceId: randomUUID(),
  idempotencyKey: idem,
  initiatedByType: 'system',
});

const release = (walletId: string, amount: number, idem: string): LedgerInput => ({
  walletId,
  entryType: 'subscription_release',
  availableDeltaMinor: amount,
  reservedDeltaMinor: -amount,
  idempotencyKey: idem,
  initiatedByType: 'system',
});

describe('ledger primitive: concurrency (NFR-FIN-02, acceptance scenario 8)', () => {
  it('cannot reserve the same funds twice under concurrent requests', async () => {
    const walletId = await newFundedWallet(1_000);
    // 10 concurrent reservations of 300 against 1,000 available: at most 3 can succeed.
    const results = await Promise.allSettled(
      Array.from({ length: 10 }, () => postLedgerEntry(ctx.db, reserve(walletId, 300))),
    );
    const ok = results.filter((r) => r.status === 'fulfilled');
    const rejected = results.filter((r): r is PromiseRejectedResult => r.status === 'rejected');
    expect(ok).toHaveLength(3);
    expect(rejected).toHaveLength(7);
    for (const r of rejected) {
      expect(r.reason).toBeInstanceOf(AppError);
      expect((r.reason as AppError).code).toBe('INSUFFICIENT_FUNDS');
    }
    expect(await balances(walletId)).toEqual({ available: 100, reserved: 900 });
    expect(await entryCount(walletId)).toBe(1 + 3); // funding + 3 reservations, no ghost rows
    expect(await reconciled(walletId)).toBe(true);
  });

  it('applies concurrent retries of one idempotent operation exactly once', async () => {
    const walletId = await newFundedWallet(0 + 1_000);
    const input = reserve(walletId, 400, 'same-key-for-all');
    const results = await Promise.all(Array.from({ length: 8 }, () => postLedgerEntry(ctx.db, input)));
    expect(results.filter((r) => !r.replayed)).toHaveLength(1);
    expect(new Set(results.map((r) => r.entry.id)).size).toBe(1);
    expect(await balances(walletId)).toEqual({ available: 600, reserved: 400 });
    expect(await entryCount(walletId)).toBe(2);
    expect(await reconciled(walletId)).toBe(true);
  });
});

describe('ledger primitive: correctness', () => {
  it('rejects an overdraft and leaves no trace', async () => {
    const walletId = await newFundedWallet(1_000);
    await expect(postLedgerEntry(ctx.db, reserve(walletId, 1_001))).rejects.toMatchObject({
      code: 'INSUFFICIENT_FUNDS',
      status: 422,
    });
    expect(await balances(walletId)).toEqual({ available: 1_000, reserved: 0 });
    expect(await entryCount(walletId)).toBe(1);
  });

  it('releases a reservation exactly once, and refuses to release more than is reserved', async () => {
    const walletId = await newFundedWallet(1_000);
    await postLedgerEntry(ctx.db, reserve(walletId, 500));
    const first = await postLedgerEntry(ctx.db, release(walletId, 500, 'release-1'));
    const retry = await postLedgerEntry(ctx.db, release(walletId, 500, 'release-1'));
    expect(first.replayed).toBe(false);
    expect(retry.replayed).toBe(true);
    expect(retry.entry.id).toBe(first.entry.id);
    expect(await balances(walletId)).toEqual({ available: 1_000, reserved: 0 });

    // A second, *different* release has nothing left to release.
    await expect(postLedgerEntry(ctx.db, release(walletId, 500, 'release-2'))).rejects.toThrow(/invariant/i);
    expect(await balances(walletId)).toEqual({ available: 1_000, reserved: 0 });
    expect(await reconciled(walletId)).toBe(true);
  });

  it('settles reserved funds out of the wallet', async () => {
    const walletId = await newFundedWallet(1_000);
    await postLedgerEntry(ctx.db, reserve(walletId, 600));
    await postLedgerEntry(ctx.db, {
      walletId,
      entryType: 'subscription_settle',
      availableDeltaMinor: 0,
      reservedDeltaMinor: -400,
      idempotencyKey: 'settle-1',
      initiatedByType: 'system',
    });
    expect(await balances(walletId)).toEqual({ available: 400, reserved: 200 });
    expect(await reconciled(walletId)).toBe(true);
  });

  it('rejects the same key with a different amount instead of treating it as a retry', async () => {
    const walletId = await newFundedWallet(1_000);
    await postLedgerEntry(ctx.db, reserve(walletId, 100, 'k-1'));
    await expect(postLedgerEntry(ctx.db, reserve(walletId, 200, 'k-1'))).rejects.toMatchObject({
      code: 'IDEMPOTENCY_KEY_REUSED',
    });
    expect(await balances(walletId)).toEqual({ available: 900, reserved: 100 });
  });

  it('refuses fractional, unsafe or all-zero amounts', async () => {
    const walletId = await newFundedWallet(1_000);
    await expect(postLedgerEntry(ctx.db, reserve(walletId, 10.5))).rejects.toThrow();
    await expect(postLedgerEntry(ctx.db, reserve(walletId, Number.MAX_SAFE_INTEGER + 2))).rejects.toThrow();
    await expect(
      postLedgerEntry(ctx.db, { ...reserve(walletId, 1), availableDeltaMinor: 0, reservedDeltaMinor: 0 }),
    ).rejects.toThrow();
    expect(await balances(walletId)).toEqual({ available: 1_000, reserved: 0 });
  });

  it('rolls everything back when a later step in the same transaction fails (NFR-FIN-05)', async () => {
    const walletId = await newFundedWallet(1_000);
    await expect(
      ctx.db.tx(async (client) => {
        await applyLedgerEntry(client, reserve(walletId, 700));
        throw new Error('simulated failure after the ledger write');
      }),
    ).rejects.toThrow(/simulated failure/);
    expect(await balances(walletId)).toEqual({ available: 1_000, reserved: 0 });
    expect(await entryCount(walletId)).toBe(1);
    expect(await reconciled(walletId)).toBe(true);
  });
});

describe('database-level guarantees (hold even if application code is wrong)', () => {
  it('ledger entries are append-only', async () => {
    const walletId = await newFundedWallet(1_000);
    await expect(
      ctx.db.query('UPDATE ledger_entries SET available_delta_minor = 999999 WHERE wallet_id = $1', [walletId]),
    ).rejects.toThrow(/append-only/);
    await expect(ctx.db.query('DELETE FROM ledger_entries WHERE wallet_id = $1', [walletId])).rejects.toThrow(
      /append-only/,
    );
    expect(await balances(walletId)).toEqual({ available: 1_000, reserved: 0 });
  });

  it('audit events are append-only', async () => {
    // Create our own row: a row-level trigger never fires on an empty table, so this
    // test must not depend on what other test files happened to leave behind.
    const action = `test.append_only.${randomUUID()}`;
    await recordAudit(ctx.db, { action, outcome: 'success' });
    await expect(ctx.db.query('DELETE FROM audit_events WHERE action = $1', [action])).rejects.toThrow(
      /append-only/,
    );
    await expect(
      ctx.db.query("UPDATE audit_events SET outcome = 'failure' WHERE action = $1", [action]),
    ).rejects.toThrow(/append-only/);
    await expect(ctx.db.query('TRUNCATE audit_events')).rejects.toThrow(/append-only/);
    const still = await ctx.db.query('SELECT outcome FROM audit_events WHERE action = $1', [action]);
    expect(still.rows).toEqual([{ outcome: 'success' }]);
  });

  it('rejects negative balances and malformed ledger rows at the schema level', async () => {
    const walletId = await newFundedWallet(100);
    await expect(
      ctx.db.query('UPDATE wallets SET available_minor = -1 WHERE id = $1', [walletId]),
    ).rejects.toThrow(/available_minor|check/i);
    // A "credit" that subtracts money violates the entry-shape constraint.
    await expect(
      ctx.db.query(
        `INSERT INTO ledger_entries (wallet_id, entry_type, available_delta_minor, reserved_delta_minor,
           available_after_minor, reserved_after_minor, initiated_by_type)
         VALUES ($1, 'test_fund_credit', -50, 0, 50, 0, 'system')`,
        [walletId],
      ),
    ).rejects.toThrow(/ledger_credit_shape/);
  });

  it('enforces one ledger entry per (wallet, type, idempotency key)', async () => {
    const walletId = await newFundedWallet(100);
    const insert = (): Promise<unknown> =>
      ctx.db.query(
        `INSERT INTO ledger_entries (wallet_id, entry_type, available_delta_minor, reserved_delta_minor,
           available_after_minor, reserved_after_minor, idempotency_key, initiated_by_type)
         VALUES ($1, 'test_fund_credit', 10, 0, 110, 0, 'dup-key-123', 'system')`,
        [walletId],
      );
    await insert();
    await expect(insert()).rejects.toThrow(/ledger_entries_idem_uidx|duplicate/);
    await ctx.db.query('UPDATE wallets SET available_minor = 110 WHERE id = $1', [walletId]);
  });
});
