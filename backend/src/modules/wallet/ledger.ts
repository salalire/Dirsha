import type { PoolClient } from 'pg';
import type { Db } from '../../db/pool.js';
import { Errors } from '../../lib/errors.js';
import { assertMinorUnits, fromDb } from '../../lib/money.js';

/**
 * THE ONLY code path that changes a wallet balance.
 *
 * Rules (see docs/BUSINESS_RULES.md):
 *  - every balance change is an append-only ledger_entries row, written in the same
 *    database transaction as the wallets update;
 *  - the wallet row is locked (SELECT ... FOR UPDATE) so concurrent operations on one
 *    wallet are serialized: funds cannot be spent twice (NFR-FIN-02);
 *  - an operation that would make `available` negative is rejected with
 *    INSUFFICIENT_FUNDS and changes nothing;
 *  - retrying with the same (wallet, entry_type, idempotency_key) returns the original
 *    entry and changes nothing (FR-LED-04, NFR-FIN-03);
 *  - amounts are integer minor units; clients never supply a balance.
 */
export type LedgerEntryType =
  | 'test_fund_credit'
  | 'subscription_reserve'
  | 'subscription_release'
  | 'subscription_settle'
  | 'adjustment';

export type InitiatorType = 'user' | 'admin' | 'system';

export interface LedgerInput {
  walletId: string;
  entryType: LedgerEntryType;
  /** Signed change to available funds, integer minor units. */
  availableDeltaMinor: number;
  /** Signed change to reserved funds, integer minor units. */
  reservedDeltaMinor: number;
  referenceType?: string;
  referenceId?: string;
  idempotencyKey?: string;
  initiatedByUserId?: string;
  initiatedByType: InitiatorType;
  description?: string;
}

export interface LedgerEntryDto {
  id: string;
  wallet_id: string;
  type: LedgerEntryType;
  status: 'posted';
  available_delta_minor: number;
  reserved_delta_minor: number;
  available_after_minor: number;
  reserved_after_minor: number;
  reference_type: string | null;
  reference_id: string | null;
  description: string | null;
  created_at: string;
}

export interface LedgerRow {
  id: string;
  wallet_id: string;
  entry_type: LedgerEntryType;
  status: 'posted';
  available_delta_minor: string;
  reserved_delta_minor: string;
  available_after_minor: string;
  reserved_after_minor: string;
  reference_type: string | null;
  reference_id: string | null;
  description: string | null;
  created_at: Date;
}

export const LEDGER_COLUMNS = `id, wallet_id, entry_type, status, available_delta_minor,
  reserved_delta_minor, available_after_minor, reserved_after_minor, reference_type,
  reference_id, description, created_at`;

export function ledgerRowToDto(r: LedgerRow): LedgerEntryDto {
  return {
    id: r.id,
    wallet_id: r.wallet_id,
    type: r.entry_type,
    status: r.status,
    available_delta_minor: fromDb(r.available_delta_minor),
    reserved_delta_minor: fromDb(r.reserved_delta_minor),
    available_after_minor: fromDb(r.available_after_minor),
    reserved_after_minor: fromDb(r.reserved_after_minor),
    reference_type: r.reference_type,
    reference_id: r.reference_id,
    description: r.description,
    created_at: r.created_at.toISOString(),
  };
}

export interface LedgerResult {
  entry: LedgerEntryDto;
  /** true when this was a retry of an already-applied operation. */
  replayed: boolean;
}

/** Must be called with a client that is inside a transaction (`db.tx`). */
export async function applyLedgerEntry(
  client: PoolClient,
  input: LedgerInput,
): Promise<LedgerResult> {
  assertSignedMinorUnits(input.availableDeltaMinor);
  assertSignedMinorUnits(input.reservedDeltaMinor);
  if (input.availableDeltaMinor === 0 && input.reservedDeltaMinor === 0) {
    throw new Error('Ledger entry must change at least one balance');
  }

  // Serialize all operations on this wallet.
  const wallet = (
    await client.query<{ available_minor: string; reserved_minor: string }>(
      'SELECT available_minor, reserved_minor FROM wallets WHERE id = $1 FOR UPDATE',
      [input.walletId],
    )
  ).rows[0];
  if (!wallet) {
    throw Errors.notFound('Wallet not found');
  }

  if (input.idempotencyKey) {
    const existing = (
      await client.query<LedgerRow>(
        `SELECT ${LEDGER_COLUMNS} FROM ledger_entries
          WHERE wallet_id = $1 AND entry_type = $2 AND idempotency_key = $3`,
        [input.walletId, input.entryType, input.idempotencyKey],
      )
    ).rows[0];
    if (existing) {
      const dto = ledgerRowToDto(existing);
      // Same key with a different amount is a client bug, not a retry.
      if (
        dto.available_delta_minor !== input.availableDeltaMinor ||
        dto.reserved_delta_minor !== input.reservedDeltaMinor
      ) {
        throw Errors.idempotencyKeyReused();
      }
      return { entry: dto, replayed: true };
    }
  }

  const availableAfter = fromDb(wallet.available_minor) + input.availableDeltaMinor;
  const reservedAfter = fromDb(wallet.reserved_minor) + input.reservedDeltaMinor;
  if (availableAfter < 0) {
    throw Errors.insufficientFunds();
  }
  if (reservedAfter < 0) {
    // Releasing/settling more than is reserved is a programming error, never user input.
    throw new Error('Ledger invariant violated: reserved balance would be negative');
  }

  const inserted = (
    await client.query<LedgerRow>(
      `INSERT INTO ledger_entries
         (wallet_id, entry_type, available_delta_minor, reserved_delta_minor,
          available_after_minor, reserved_after_minor, reference_type, reference_id,
          idempotency_key, initiated_by_user_id, initiated_by_type, description)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
       RETURNING ${LEDGER_COLUMNS}`,
      [
        input.walletId,
        input.entryType,
        input.availableDeltaMinor,
        input.reservedDeltaMinor,
        availableAfter,
        reservedAfter,
        input.referenceType ?? null,
        input.referenceId ?? null,
        input.idempotencyKey ?? null,
        input.initiatedByUserId ?? null,
        input.initiatedByType,
        input.description ?? null,
      ],
    )
  ).rows[0];
  if (!inserted) throw new Error('ledger insert returned no row');

  await client.query('UPDATE wallets SET available_minor = $2, reserved_minor = $3 WHERE id = $1', [
    input.walletId,
    availableAfter,
    reservedAfter,
  ]);

  return { entry: ledgerRowToDto(inserted), replayed: false };
}

/** Convenience wrapper: apply one entry in its own transaction. */
export function postLedgerEntry(db: Db, input: LedgerInput): Promise<LedgerResult> {
  return db.tx((client) => applyLedgerEntry(client, input));
}

function assertSignedMinorUnits(n: number): void {
  if (n === 0) return;
  assertMinorUnits(Math.abs(n));
}
