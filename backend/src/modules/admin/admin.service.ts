import type { Db } from '../../db/pool.js';
import type { AccountStatus, AuthUser, Role, VerificationStatus } from '../../http/types.js';
import type { Pagination } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import { fromDb } from '../../lib/money.js';
import { recordAudit } from '../audit/audit.service.js';
import { applyLedgerEntry } from '../wallet/ledger.js';

export interface AuditEventDto {
  id: string;
  actor_user_id: string | null;
  actor_role: string | null;
  action: string;
  target_type: string | null;
  target_id: string | null;
  outcome: 'success' | 'failure' | 'denied';
  request_id: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
}

interface AuditRow {
  id: string;
  actor_user_id: string | null;
  actor_role: string | null;
  action: string;
  target_type: string | null;
  target_id: string | null;
  outcome: 'success' | 'failure' | 'denied';
  request_id: string | null;
  metadata: Record<string, unknown>;
  created_at: Date;
}

export interface AdminUserDto {
  id: string;
  email: string;
  full_name: string;
  phone: string | null;
  role: Role;
  account_status: AccountStatus;
  verification_status: VerificationStatus;
  created_at: string;
}

interface UserRow {
  id: string;
  email: string;
  full_name: string;
  phone: string | null;
  role: Role;
  account_status: AccountStatus;
  verification_status: VerificationStatus;
  created_at: Date;
}

export async function listAuditEvents(
  db: Db,
  opts: { page: number; page_size: number; actor_user_id?: string; action?: string },
): Promise<{ data: AuditEventDto[]; pagination: Pagination }> {
  const conditions: string[] = [];
  const params: unknown[] = [];

  if (opts.actor_user_id) {
    params.push(opts.actor_user_id);
    conditions.push(`actor_user_id = $${params.length}`);
  }
  if (opts.action) {
    params.push(opts.action);
    conditions.push(`action = $${params.length}`);
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const total = fromDb(
    (
      await db.query<{ n: string }>(
        `SELECT count(*)::bigint AS n FROM audit_events ${whereClause}`,
        params,
      )
    ).rows[0]?.n,
  );

  const limitIdx = params.length + 1;
  const offsetIdx = params.length + 2;
  params.push(opts.page_size, (opts.page - 1) * opts.page_size);

  const { rows } = await db.query<AuditRow>(
    `SELECT id, actor_user_id, actor_role, action, target_type, target_id,
            outcome, request_id, metadata, created_at
     FROM audit_events
     ${whereClause}
     ORDER BY created_at DESC, id DESC
     LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
    params,
  );

  return {
    data: rows.map((r) => ({
      id: r.id,
      actor_user_id: r.actor_user_id,
      actor_role: r.actor_role,
      action: r.action,
      target_type: r.target_type,
      target_id: r.target_id,
      outcome: r.outcome,
      request_id: r.request_id,
      metadata: r.metadata ?? {},
      created_at: r.created_at.toISOString(),
    })),
    pagination: { page: opts.page, page_size: opts.page_size, total },
  };
}

export async function listAllUsers(
  db: Db,
  opts: { page: number; page_size: number; role?: Role; account_status?: AccountStatus },
): Promise<{ data: AdminUserDto[]; pagination: Pagination }> {
  const conditions: string[] = [];
  const params: unknown[] = [];

  if (opts.role) {
    params.push(opts.role);
    conditions.push(`role = $${params.length}`);
  }
  if (opts.account_status) {
    params.push(opts.account_status);
    conditions.push(`account_status = $${params.length}`);
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const total = fromDb(
    (
      await db.query<{ n: string }>(
        `SELECT count(*)::bigint AS n FROM users ${whereClause}`,
        params,
      )
    ).rows[0]?.n,
  );

  const limitIdx = params.length + 1;
  const offsetIdx = params.length + 2;
  params.push(opts.page_size, (opts.page - 1) * opts.page_size);

  const { rows } = await db.query<UserRow>(
    `SELECT id, email, full_name, phone, role, account_status, verification_status, created_at
     FROM users
     ${whereClause}
     ORDER BY created_at DESC, id DESC
     LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
    params,
  );

  return {
    data: rows.map((r) => ({
      id: r.id,
      email: r.email,
      full_name: r.full_name,
      phone: r.phone,
      role: r.role,
      account_status: r.account_status,
      verification_status: r.verification_status,
      created_at: r.created_at.toISOString(),
    })),
    pagination: { page: opts.page, page_size: opts.page_size, total },
  };
}

export async function approveIpo(
  db: Db,
  admin: AuthUser,
  ipoId: string,
  opts: { notes?: string; requestId: string },
): Promise<{ ipo_id: string; status: string }> {
  return db.tx(async (client) => {
    const ipo = (
      await client.query<{ id: string; status: string }>(
        'SELECT id, status FROM ipos WHERE id = $1 FOR UPDATE',
        [ipoId],
      )
    ).rows[0];

    if (!ipo) throw Errors.notFound('IPO not found');
    if (ipo.status !== 'submitted' && ipo.status !== 'under_review') {
      throw Errors.conflict(`Cannot approve IPO currently in status '${ipo.status}'`);
    }

    const nextStatus = 'approved';
    await client.query('UPDATE ipos SET status = $2 WHERE id = $1', [ipoId, nextStatus]);

    await client.query(
      `INSERT INTO ipo_status_history (ipo_id, from_status, to_status, changed_by, reason)
       VALUES ($1, $2, $3, $4, $5)`,
      [ipoId, ipo.status, nextStatus, admin.id, opts.notes ?? 'Approved by administrator'],
    );

    await recordAudit(client, {
      actorUserId: admin.id,
      actorRole: admin.role,
      action: 'ipo.approve',
      targetType: 'ipo',
      targetId: ipoId,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: { from_status: ipo.status, to_status: nextStatus, notes: opts.notes ?? null },
    });

    return { ipo_id: ipoId, status: nextStatus };
  });
}

export async function rejectIpo(
  db: Db,
  admin: AuthUser,
  ipoId: string,
  opts: { reason: string; requestId: string },
): Promise<{ ipo_id: string; status: string }> {
  return db.tx(async (client) => {
    const ipo = (
      await client.query<{ id: string; status: string }>(
        'SELECT id, status FROM ipos WHERE id = $1 FOR UPDATE',
        [ipoId],
      )
    ).rows[0];

    if (!ipo) throw Errors.notFound('IPO not found');
    if (ipo.status !== 'submitted' && ipo.status !== 'under_review') {
      throw Errors.conflict(`Cannot reject IPO currently in status '${ipo.status}'`);
    }

    const nextStatus = 'rejected';
    await client.query('UPDATE ipos SET status = $2 WHERE id = $1', [ipoId, nextStatus]);

    await client.query(
      `INSERT INTO ipo_status_history (ipo_id, from_status, to_status, changed_by, reason)
       VALUES ($1, $2, $3, $4, $5)`,
      [ipoId, ipo.status, nextStatus, admin.id, opts.reason],
    );

    await recordAudit(client, {
      actorUserId: admin.id,
      actorRole: admin.role,
      action: 'ipo.reject',
      targetType: 'ipo',
      targetId: ipoId,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: { from_status: ipo.status, to_status: nextStatus, reason: opts.reason },
    });

    return { ipo_id: ipoId, status: nextStatus };
  });
}

export async function closeIpo(
  db: Db,
  admin: AuthUser,
  ipoId: string,
  opts: { reason?: string; requestId: string },
): Promise<{ ipo_id: string; status: string }> {
  return db.tx(async (client) => {
    const ipo = (
      await client.query<{ id: string; status: string }>(
        'SELECT id, status FROM ipos WHERE id = $1 FOR UPDATE',
        [ipoId],
      )
    ).rows[0];

    if (!ipo) throw Errors.notFound('IPO not found');
    if (ipo.status !== 'open') {
      throw Errors.conflict(`Cannot close IPO currently in status '${ipo.status}'`);
    }

    const nextStatus = 'closed';
    await client.query('UPDATE ipos SET status = $2 WHERE id = $1', [ipoId, nextStatus]);

    await client.query(
      `INSERT INTO ipo_status_history (ipo_id, from_status, to_status, changed_by, reason)
       VALUES ($1, $2, $3, $4, $5)`,
      [ipoId, ipo.status, nextStatus, admin.id, opts.reason ?? 'Closed for subscription'],
    );

    await recordAudit(client, {
      actorUserId: admin.id,
      actorRole: admin.role,
      action: 'ipo.close',
      targetType: 'ipo',
      targetId: ipoId,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: { from_status: ipo.status, to_status: nextStatus },
    });

    return { ipo_id: ipoId, status: nextStatus };
  });
}

interface ActiveSubRow {
  id: string;
  investor_id: string;
  quantity: string;
  amount_minor: string;
  created_at: Date;
}

export interface AllocationSummary {
  ipo_id: string;
  total_shares_offered: number;
  total_shares_requested: number;
  total_shares_allocated: number;
  subscriptions_count: number;
  status: string;
}

/**
 * Executes the Pro-Rata Allocation & Settlement Engine (T-2.6; FR-ALC-01..02, FR-LED-03).
 *
 * Rules (docs/BUSINESS_RULES.md Part B, B6-B8, B10-B11):
 *  - Distributes whole shares only (no fractional shares).
 *  - If requested <= offered: 100% allocation.
 *  - If requested > offered (oversubscribed):
 *    - Base allocation: floor(quantity * offered / requested)
 *    - Leftovers distributed one by one to largest remainder: (quantity * offered) % requested
 *    - Remainder ties broken by earliest subscription time, then subscription id.
 *  - Ledger operations:
 *    - Allocated shares: subscription_settle (leaves wallet, decreases reserved).
 *    - Unallocated shares: subscription_release (returns reserved to available).
 */
export async function allocateIpo(
  db: Db,
  admin: AuthUser,
  ipoId: string,
  opts: { requestId: string },
): Promise<AllocationSummary> {
  return db.tx(async (client) => {
    const ipo = (
      await client.query<{
        id: string;
        status: string;
        total_shares: string;
        price_per_share_minor: string;
      }>('SELECT id, status, total_shares, price_per_share_minor FROM ipos WHERE id = $1 FOR UPDATE', [
        ipoId,
      ])
    ).rows[0];

    if (!ipo) throw Errors.notFound('IPO not found');
    if (ipo.status !== 'closed' && ipo.status !== 'open') {
      throw Errors.conflict(`Cannot allocate IPO currently in status '${ipo.status}'. Must be open or closed.`);
    }

    const totalOffered = fromDb(ipo.total_shares);
    const priceMinor = fromDb(ipo.price_per_share_minor);

    // Fetch active reserved subscriptions
    const { rows: subs } = await client.query<ActiveSubRow>(
      `SELECT id, investor_id, quantity, amount_minor, created_at
       FROM subscriptions
       WHERE ipo_id = $1 AND status = 'reserved'
       ORDER BY created_at ASC, id ASC`,
      [ipoId],
    );

    const totalRequested = subs.reduce((sum, s) => sum + fromDb(s.quantity), 0);
    const subAllocations = new Map<string, number>();

    if (totalRequested <= totalOffered) {
      // 100% allocation for everyone
      for (const s of subs) {
        subAllocations.set(s.id, fromDb(s.quantity));
      }
    } else {
      // Oversubscribed pro-rata with largest remainder
      let allocatedTotal = 0;
      interface RemainderItem {
        id: string;
        remainder: number;
        createdAt: Date;
      }
      const remainders: RemainderItem[] = [];

      for (const s of subs) {
        const qty = fromDb(s.quantity);
        const base = Math.floor((qty * totalOffered) / totalRequested);
        subAllocations.set(s.id, base);
        allocatedTotal += base;
        const remainder = (qty * totalOffered) % totalRequested;
        remainders.push({ id: s.id, remainder, createdAt: s.created_at });
      }

      // Sort remainders descending, breaking ties by earliest createdAt, then id
      remainders.sort((a, b) => {
        if (b.remainder !== a.remainder) return b.remainder - a.remainder;
        const diff = a.createdAt.getTime() - b.createdAt.getTime();
        return diff !== 0 ? diff : a.id.localeCompare(b.id);
      });

      let leftover = totalOffered - allocatedTotal;
      for (let i = 0; i < remainders.length && leftover > 0; i++) {
        const item = remainders[i];
        if (!item) break;
        subAllocations.set(item.id, (subAllocations.get(item.id) ?? 0) + 1);
        leftover--;
      }
    }

    let actualAllocatedTotal = 0;

    // Apply financial movements for each subscription
    for (const s of subs) {
      const allocatedQty = subAllocations.get(s.id) ?? 0;
      const requestedQty = fromDb(s.quantity);
      actualAllocatedTotal += allocatedQty;

      const allocatedAmountMinor = allocatedQty * priceMinor;
      const unallocatedAmountMinor = (requestedQty - allocatedQty) * priceMinor;

      // Find user wallet
      const wallet = (
        await client.query<{ id: string }>('SELECT id FROM wallets WHERE user_id = $1', [
          s.investor_id,
        ])
      ).rows[0];
      if (!wallet) throw new Error(`Wallet not found for investor ${s.investor_id}`);

      let finalStatus: 'allocated' | 'partially_allocated' | 'released';
      if (allocatedQty === requestedQty) {
        finalStatus = 'allocated';
      } else if (allocatedQty > 0) {
        finalStatus = 'partially_allocated';
      } else {
        finalStatus = 'released';
      }

      // 1. Settle allocated funds (reserved -> paid out of wallet)
      if (allocatedAmountMinor > 0) {
        await applyLedgerEntry(client, {
          walletId: wallet.id,
          entryType: 'subscription_settle',
          availableDeltaMinor: 0,
          reservedDeltaMinor: -allocatedAmountMinor,
          referenceType: 'subscription',
          referenceId: s.id,
          idempotencyKey: `settle-${s.id}`,
          initiatedByUserId: admin.id,
          initiatedByType: 'admin',
          description: `Settlement of ${allocatedQty} shares for ${ipoId}`,
        });
      }

      // 2. Release unallocated funds back to available
      if (unallocatedAmountMinor > 0) {
        await applyLedgerEntry(client, {
          walletId: wallet.id,
          entryType: 'subscription_release',
          availableDeltaMinor: unallocatedAmountMinor,
          reservedDeltaMinor: -unallocatedAmountMinor,
          referenceType: 'subscription',
          referenceId: s.id,
          idempotencyKey: `release-${s.id}`,
          initiatedByUserId: admin.id,
          initiatedByType: 'admin',
          description: `Refund / release of ${requestedQty - allocatedQty} unallocated shares for ${ipoId}`,
        });
      }

      // Update subscription status and allocated_quantity
      await client.query(
        'UPDATE subscriptions SET allocated_quantity = $2, status = $3 WHERE id = $1',
        [s.id, allocatedQty, finalStatus],
      );
    }

    const nextStatus = 'allocated';
    await client.query('UPDATE ipos SET status = $2 WHERE id = $1', [ipoId, nextStatus]);

    await client.query(
      `INSERT INTO ipo_status_history (ipo_id, from_status, to_status, changed_by, reason)
       VALUES ($1, $2, $3, $4, $5)`,
      [ipoId, ipo.status, nextStatus, admin.id, `Pro-rata allocation executed for ${subs.length} subscriptions`],
    );

    await recordAudit(client, {
      actorUserId: admin.id,
      actorRole: admin.role,
      action: 'ipo.allocate',
      targetType: 'ipo',
      targetId: ipoId,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: {
        total_offered: totalOffered,
        total_requested: totalRequested,
        total_allocated: actualAllocatedTotal,
        subscriptions_count: subs.length,
      },
    });

    return {
      ipo_id: ipoId,
      total_shares_offered: totalOffered,
      total_shares_requested: totalRequested,
      total_shares_allocated: actualAllocatedTotal,
      subscriptions_count: subs.length,
      status: nextStatus,
    };
  });
}
