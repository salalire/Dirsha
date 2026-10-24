import { randomUUID } from "node:crypto";
import type { Db } from "../../db/pool.js";
import type { AuthUser } from "../../http/types.js";
import type { Pagination } from "../../http/validate.js";
import { Errors } from "../../lib/errors.js";
import { fromDb } from "../../lib/money.js";
import { recordAudit } from "../audit/audit.service.js";
import { applyLedgerEntry } from "../wallet/ledger.js";

export const SUBSCRIPTION_STATUSES = [
  "reserved",
  "allocated",
  "partially_allocated",
  "released",
  "cancelled",
] as const;

export type SubscriptionStatus = (typeof SUBSCRIPTION_STATUSES)[number];

export interface SubscriptionDto {
  id: string;
  ipo_id: string;
  investor_id: string;
  quantity: number;
  amount_minor: number;
  allocated_quantity: number;
  status: SubscriptionStatus;
  reservation_ledger_entry_id: string | null;
  created_at: string;
  updated_at: string;
  ipo_title?: string;
  ipo_symbol?: string;
  company_name?: string;
  price_per_share_minor?: number;
  investor_name?: string;
  investor_email?: string;
}

export interface SubscriptionRow {
  id: string;
  ipo_id: string;
  investor_id: string;
  quantity: string;
  amount_minor: string;
  allocated_quantity: string;
  status: SubscriptionStatus;
  reservation_ledger_entry_id: string | null;
  idempotency_key: string;
  created_at: Date;
  updated_at: Date;
  ipo_title?: string;
  ipo_symbol?: string;
  company_name?: string;
  price_per_share_minor?: string;
  investor_name?: string;
  investor_email?: string;
}

export function subscriptionRowToDto(r: SubscriptionRow): SubscriptionDto {
  const dto: SubscriptionDto = {
    id: r.id,
    ipo_id: r.ipo_id,
    investor_id: r.investor_id,
    quantity: fromDb(r.quantity),
    amount_minor: fromDb(r.amount_minor),
    allocated_quantity: fromDb(r.allocated_quantity),
    status: r.status,
    reservation_ledger_entry_id: r.reservation_ledger_entry_id,
    created_at: r.created_at.toISOString(),
    updated_at: r.updated_at.toISOString(),
  };
  if (r.ipo_title !== undefined) dto.ipo_title = r.ipo_title;
  if (r.ipo_symbol !== undefined) dto.ipo_symbol = r.ipo_symbol;
  if (r.company_name !== undefined) dto.company_name = r.company_name;
  if (r.price_per_share_minor !== undefined && r.price_per_share_minor !== null) {
    dto.price_per_share_minor = fromDb(r.price_per_share_minor);
  }
  if (r.investor_name !== undefined) dto.investor_name = r.investor_name;
  if (r.investor_email !== undefined) dto.investor_email = r.investor_email;
  return dto;
}

/**
 * Creates an IPO subscription with atomic funds reservation.
 *
 * Rules:
 *  - Investor account must be active (B3; verification_status not required for MVP).
 *  - IPO must be in status 'open' and opens_at <= now() < closes_at (B5).
 *  - Quantity must satisfy min/max constraints of the IPO (B2).
 *  - Only one active subscription allowed per investor per IPO (B4).
 *  - Deducts from available balance and credits reserved balance via ledger_entries (B1).
 *  - Enforces request-level idempotency via (investor_id, idempotency_key).
 */
export async function createSubscription(
  db: Db,
  user: AuthUser,
  input: {
    ipoId: string;
    quantity: number;
    idempotencyKey: string;
    requestId: string;
  },
): Promise<{ subscription: SubscriptionDto; replayed: boolean }> {
  if (user.accountStatus !== "active") {
    throw Errors.accountSuspended();
  }

  const ipo = (
    await db.query<{
      id: string;
      status: string;
      price_per_share_minor: string;
      min_shares_per_subscription: string | null;
      max_shares_per_subscription: string | null;
      opens_at: Date;
      closes_at: Date;
    }>(
      `SELECT id, status, price_per_share_minor,
              min_shares_per_subscription, max_shares_per_subscription,
              opens_at, closes_at
       FROM ipos WHERE id = $1`,
      [input.ipoId],
    )
  ).rows[0];

  if (!ipo) {
    throw Errors.notFound("IPO not found");
  }

  const now = new Date();
  if (ipo.status !== "open" || now < ipo.opens_at || now >= ipo.closes_at) {
    throw Errors.ipoNotOpen("IPO is not open for subscription");
  }

  const minShares =
    ipo.min_shares_per_subscription !== null
      ? fromDb(ipo.min_shares_per_subscription)
      : null;
  const maxShares =
    ipo.max_shares_per_subscription !== null
      ? fromDb(ipo.max_shares_per_subscription)
      : null;

  if (minShares !== null && input.quantity < minShares) {
    throw Errors.validation([
      {
        field: "quantity",
        message: `Quantity must be at least ${minShares} shares`,
      },
    ]);
  }
  if (maxShares !== null && input.quantity > maxShares) {
    throw Errors.validation([
      {
        field: "quantity",
        message: `Quantity cannot exceed ${maxShares} shares`,
      },
    ]);
  }

  const pricePerShare = fromDb(ipo.price_per_share_minor);
  const amountMinor = input.quantity * pricePerShare;

  return db.tx(async (client) => {
    // 0. Lock the IPO row (shared) and re-check it is still open INSIDE the transaction.
    //    Allocation/close take FOR UPDATE on the same row, so a subscription can never
    //    slip in after allocation has read the list of reserved subscriptions.
    const locked = (
      await client.query<{ status: string; closes_at: Date }>(
        "SELECT status, closes_at FROM ipos WHERE id = $1 FOR SHARE",
        [input.ipoId],
      )
    ).rows[0];
    if (!locked || locked.status !== "open" || new Date() >= locked.closes_at) {
      throw Errors.ipoNotOpen("IPO is not open for subscription");
    }

    // 1. Idempotency check:
    const existing = (
      await client.query<SubscriptionRow>(
        "SELECT * FROM subscriptions WHERE investor_id = $1 AND idempotency_key = $2",
        [user.id, input.idempotencyKey],
      )
    ).rows[0];

    if (existing) {
      if (
        existing.ipo_id === input.ipoId &&
        fromDb(existing.quantity) === input.quantity
      ) {
        return { subscription: subscriptionRowToDto(existing), replayed: true };
      }
      throw Errors.idempotencyKeyReused();
    }

    // 2. Enforce one active subscription per investor per IPO (B4)
    const activeSub = (
      await client.query<{ id: string }>(
        `SELECT id FROM subscriptions
         WHERE ipo_id = $1 AND investor_id = $2
           AND status IN ('reserved', 'allocated', 'partially_allocated')
         LIMIT 1`,
        [input.ipoId, user.id],
      )
    ).rows[0];

    if (activeSub) {
      throw Errors.conflict(
        "An active subscription already exists for this IPO",
      );
    }

    // 3. Investor wallet
    const wallet = (
      await client.query<{ id: string }>(
        "SELECT id FROM wallets WHERE user_id = $1",
        [user.id],
      )
    ).rows[0];

    if (!wallet) {
      throw Errors.notFound("Wallet not found");
    }

    const subscriptionId = randomUUID();

    // 4. Reserve funds atomically (locks wallet row FOR UPDATE, throws INSUFFICIENT_FUNDS if needed)
    const { entry: ledgerEntry } = await applyLedgerEntry(client, {
      walletId: wallet.id,
      entryType: "subscription_reserve",
      availableDeltaMinor: -amountMinor,
      reservedDeltaMinor: amountMinor,
      referenceType: "subscription",
      referenceId: subscriptionId,
      idempotencyKey: input.idempotencyKey,
      initiatedByUserId: user.id,
      initiatedByType: "user",
      description: `Subscription reservation for ${input.quantity} shares`,
    });

    // 5. Insert subscription record. The partial unique index is the last line of defence
    //    against two concurrent requests (different keys) both passing check 2 above;
    //    the transaction rolls back, so the reservation made in step 4 is undone too.
    let inserted: SubscriptionRow | undefined;
    try {
      inserted = (
        await client.query<SubscriptionRow>(
          `INSERT INTO subscriptions
           (id, ipo_id, investor_id, quantity, amount_minor,
            allocated_quantity, status, reservation_ledger_entry_id, idempotency_key)
         VALUES ($1, $2, $3, $4, $5, 0, 'reserved', $6, $7)
         RETURNING *`,
          [
            subscriptionId,
            input.ipoId,
            user.id,
            input.quantity,
            amountMinor,
            ledgerEntry.id,
            input.idempotencyKey,
          ],
        )
      ).rows[0];
    } catch (err) {
      if ((err as { code?: string }).code === "23505") {
        throw Errors.conflict(
          "An active subscription already exists for this IPO",
        );
      }
      throw err;
    }

    if (!inserted) {
      throw new Error("Subscription insert returned no row");
    }

    // 6. Record audit event
    await recordAudit(client, {
      actorUserId: user.id,
      actorRole: user.role,
      action: "subscription.create",
      targetType: "subscription",
      targetId: subscriptionId,
      outcome: "success",
      requestId: input.requestId,
      metadata: {
        ipo_id: input.ipoId,
        quantity: input.quantity,
        amount_minor: amountMinor,
        reservation_ledger_entry_id: ledgerEntry.id,
      },
    });

    return { subscription: subscriptionRowToDto(inserted), replayed: false };
  });
}

/** Lists subscriptions. Investors see only their own; Admins see all. */
export async function listSubscriptions(
  db: Db,
  user: AuthUser,
  opts: {
    page: number;
    page_size: number;
    ipo_id?: string;
    status?: SubscriptionStatus;
  },
): Promise<{ data: SubscriptionDto[]; pagination: Pagination }> {
  const conditions: string[] = [];
  const params: unknown[] = [];

  if (user.role !== "admin") {
    params.push(user.id);
    conditions.push(`s.investor_id = $${params.length}`);
  }

  if (opts.ipo_id) {
    params.push(opts.ipo_id);
    conditions.push(`s.ipo_id = $${params.length}`);
  }

  if (opts.status) {
    params.push(opts.status);
    conditions.push(`s.status = $${params.length}`);
  }

  const whereClause = conditions.length
    ? `WHERE ${conditions.join(" AND ")}`
    : "";

  const total = fromDb(
    (
      await db.query<{ n: string }>(
        `SELECT count(*)::bigint AS n FROM subscriptions s ${whereClause}`,
        params,
      )
    ).rows[0]?.n,
  );

  const limitIdx = params.length + 1;
  const offsetIdx = params.length + 2;
  params.push(opts.page_size, (opts.page - 1) * opts.page_size);

  const { rows } = await db.query<SubscriptionRow>(
    `SELECT s.*,
            i.title AS ipo_title,
            i.symbol AS ipo_symbol,
            i.price_per_share_minor,
            COALESCE(c.trade_name, c.legal_name) AS company_name,
            u.full_name AS investor_name,
            u.email AS investor_email
     FROM subscriptions s
     JOIN ipos i ON i.id = s.ipo_id
     JOIN companies c ON c.id = i.company_id
     JOIN users u ON u.id = s.investor_id
     ${whereClause}
     ORDER BY s.created_at DESC, s.id DESC
     LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
    params,
  );

  return {
    data: rows.map(subscriptionRowToDto),
    pagination: { page: opts.page, page_size: opts.page_size, total },
  };
}

/** Fetches a single subscription. Investors only see their own; Admins can see any. */
export async function getSubscription(
  db: Db,
  user: AuthUser,
  id: string,
): Promise<SubscriptionDto | null> {
  const params: unknown[] = [id];
  let where = "s.id = $1";
  if (user.role !== "admin") {
    params.push(user.id);
    where += " AND s.investor_id = $2";
  }

  const { rows } = await db.query<SubscriptionRow>(
    `SELECT s.*,
            i.title AS ipo_title,
            i.symbol AS ipo_symbol,
            i.price_per_share_minor,
            COALESCE(c.trade_name, c.legal_name) AS company_name,
            u.full_name AS investor_name,
            u.email AS investor_email
     FROM subscriptions s
     JOIN ipos i ON i.id = s.ipo_id
     JOIN companies c ON c.id = i.company_id
     JOIN users u ON u.id = s.investor_id
     WHERE ${where}`,
    params,
  );

  const row = rows[0];
  return row ? subscriptionRowToDto(row) : null;
}
