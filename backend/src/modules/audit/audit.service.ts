import type { Role } from '../../http/types.js';

/** Anything with a pg-style `query` (the pool wrapper or a transaction client). */
export interface Queryable {
  query(text: string, params?: unknown[]): Promise<unknown>;
}

export interface AuditInput {
  actorUserId?: string | null;
  actorRole?: Role | null;
  action: string;
  targetType?: string | null;
  targetId?: string | null;
  outcome: 'success' | 'failure' | 'denied';
  requestId?: string | null;
  /** Must never contain passwords, tokens or secrets (FR-ADM-05). */
  metadata?: Record<string, unknown>;
}

/**
 * Append an audit event (actor, action, target, outcome, correlation id: FR-ADM-03).
 * Pass a transaction client to make the event commit or roll back with the action.
 */
export async function recordAudit(q: Queryable, e: AuditInput): Promise<void> {
  await q.query(
    `INSERT INTO audit_events
       (actor_user_id, actor_role, action, target_type, target_id, outcome, request_id, metadata)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [
      e.actorUserId ?? null,
      e.actorRole ?? null,
      e.action,
      e.targetType ?? null,
      e.targetId ?? null,
      e.outcome,
      e.requestId ?? null,
      JSON.stringify(e.metadata ?? {}),
    ],
  );
}
