import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';
import type { Pagination } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import { CURRENCY, fromDb } from '../../lib/money.js';
import { recordAudit } from '../audit/audit.service.js';
import {
  applyLedgerEntry,
  LEDGER_COLUMNS,
  ledgerRowToDto,
  type LedgerEntryDto,
  type LedgerRow,
} from './ledger.js';

/** Per-request ceiling for simulated test funds: 100,000 ETB in santim. */
export const MAX_TEST_FUND_MINOR = 10_000_000;

export interface WalletDto {
  id: string;
  currency: typeof CURRENCY;
  /** Always true in this prototype: balances are simulated, not real money (FR-LED-01). */
  simulated: true;
  available_minor: number;
  reserved_minor: number;
  total_minor: number;
  updated_at: string;
}

interface WalletRow {
  id: string;
  available_minor: string;
  reserved_minor: string;
  updated_at: Date;
}

function walletToDto(r: WalletRow): WalletDto {
  const available = fromDb(r.available_minor);
  const reserved = fromDb(r.reserved_minor);
  return {
    id: r.id,
    currency: CURRENCY,
    simulated: true,
    available_minor: available,
    reserved_minor: reserved,
    total_minor: available + reserved,
    updated_at: r.updated_at.toISOString(),
  };
}

/** The caller's own wallet. Ownership is by construction: the query filters on user id. */
export async function getOwnWallet(db: Db, user: AuthUser): Promise<WalletDto> {
  const { rows } = await db.query<WalletRow>(
    'SELECT id, available_minor, reserved_minor, updated_at FROM wallets WHERE user_id = $1',
    [user.id],
  );
  const row = rows[0];
  if (!row) throw Errors.notFound('Wallet not found');
  return walletToDto(row);
}

export async function listOwnTransactions(
  db: Db,
  user: AuthUser,
  opts: { page: number; page_size: number },
): Promise<{ data: LedgerEntryDto[]; pagination: Pagination }> {
  const wallet = await getOwnWallet(db, user);

  const total = fromDb(
    (
      await db.query<{ n: string }>(
        'SELECT count(*)::bigint AS n FROM ledger_entries WHERE wallet_id = $1',
        [wallet.id],
      )
    ).rows[0]?.n,
  );
  const { rows } = await db.query<LedgerRow>(
    `SELECT ${LEDGER_COLUMNS} FROM ledger_entries
      WHERE wallet_id = $1
      ORDER BY created_at DESC, id DESC
      LIMIT $2 OFFSET $3`,
    [wallet.id, opts.page_size, (opts.page - 1) * opts.page_size],
  );
  return {
    data: rows.map(ledgerRowToDto),
    pagination: { page: opts.page, page_size: opts.page_size, total },
  };
}

/**
 * DEV/TEST ONLY. Credits SIMULATED funds to the caller's own wallet.
 * The route that calls this is only mounted when ENABLE_TEST_FUNDS=true, which the
 * environment validation refuses in production. It is not a general "add balance"
 * endpoint: it needs an Idempotency-Key, caps each call, only targets the caller's own
 * wallet, goes through the ledger, and is audited.
 */
export async function creditOwnTestFunds(
  db: Db,
  user: AuthUser,
  input: { amountMinor: number; idempotencyKey: string; requestId: string },
): Promise<{ entry: LedgerEntryDto; wallet: WalletDto; replayed: boolean }> {
  return db.tx(async (client) => {
    const walletRow = (
      await client.query<{ id: string }>('SELECT id FROM wallets WHERE user_id = $1', [user.id])
    ).rows[0];
    if (!walletRow) throw Errors.notFound('Wallet not found');

    const { entry, replayed } = await applyLedgerEntry(client, {
      walletId: walletRow.id,
      entryType: 'test_fund_credit',
      availableDeltaMinor: input.amountMinor,
      reservedDeltaMinor: 0,
      idempotencyKey: input.idempotencyKey,
      initiatedByUserId: user.id,
      initiatedByType: 'user',
      description: 'Simulated test funds (not real money)',
    });

    if (!replayed) {
      await recordAudit(client, {
        actorUserId: user.id,
        actorRole: user.role,
        action: 'wallet.test_fund_credit',
        targetType: 'wallet',
        targetId: walletRow.id,
        outcome: 'success',
        requestId: input.requestId,
        metadata: { amount_minor: input.amountMinor, ledger_entry_id: entry.id },
      });
    }

    const wallet = (
      await client.query<WalletRow>(
        'SELECT id, available_minor, reserved_minor, updated_at FROM wallets WHERE id = $1',
        [walletRow.id],
      )
    ).rows[0];
    if (!wallet) throw new Error('wallet disappeared inside transaction');
    return { entry, wallet: walletToDto(wallet), replayed };
  });
}
