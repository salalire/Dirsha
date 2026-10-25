import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';
import { Errors } from '../../lib/errors.js';
import { fromDb } from '../../lib/money.js';
import { recordAudit } from '../audit/audit.service.js';

export interface BrokerProfileDto {
  id: string;
  owner_user_id: string;
  firm_legal_name: string;
  license_number: string;
  license_category: string;
  licensing_authority: string;
  onboarding_status: string;
  representative_name: string | null;
  representative_email: string | null;
  representative_phone: string | null;
  created_at: string;
}

export interface BrokerDashboardDto {
  broker: BrokerProfileDto;
  metrics: {
    total_active_clients: number;
    pending_client_requests: number;
    available_ipos_count: number;
    assisted_orders_count: number;
  };
}

export interface ClientRelationshipDto {
  id: string;
  broker_id: string;
  broker_firm_name?: string;
  investor_id: string;
  investor_name: string;
  investor_email: string;
  investor_phone: string | null;
  investor_verification_status: string;
  relationship_type: 'advisory' | 'discretionary' | 'execution_only';
  status: 'pending' | 'active' | 'rejected' | 'revoked';
  notes: string | null;
  requested_by: 'broker' | 'investor';
  requested_at: string;
  responded_at: string | null;
}

export interface AuthorizedClientDetailDto {
  relationship: ClientRelationshipDto;
  client: {
    id: string;
    full_name: string;
    email: string;
    phone: string | null;
    verification_status: string;
  };
  wallet: {
    available_minor: number;
    reserved_minor: number;
    total_minor: number;
    currency: string;
  };
  holdings: Array<{
    ipo_id: string;
    symbol: string;
    company_name: string;
    quantity: number;
    reserved_quantity: number;
  }>;
}

/**
 * Retrieves the broker record associated with the caller.
 * Requires role 'broker'.
 */
export async function getBrokerProfile(db: Db, user: AuthUser): Promise<BrokerProfileDto> {
  if (user.role !== 'broker' && user.role !== 'admin') {
    throw Errors.forbidden('Only registered brokers can access this resource');
  }

  const { rows } = await db.query<{
    id: string;
    owner_user_id: string;
    firm_legal_name: string;
    license_number: string;
    license_category: string;
    licensing_authority: string;
    onboarding_status: string;
    representative_name: string | null;
    representative_email: string | null;
    representative_phone: string | null;
    created_at: Date;
  }>(
    `SELECT id, owner_user_id, legal_name AS firm_legal_name, license_number, license_category,
            licensing_authority, onboarding_status, representative_name,
            representative_email, representative_phone, created_at
     FROM brokers
     WHERE owner_user_id = $1`,
    [user.id],
  );

  const row = rows[0];
  if (!row) {
    throw Errors.notFound('Broker profile not found. Please complete broker onboarding.');
  }

  return {
    id: row.id,
    owner_user_id: row.owner_user_id,
    firm_legal_name: row.firm_legal_name,
    license_number: row.license_number,
    license_category: row.license_category,
    licensing_authority: row.licensing_authority,
    onboarding_status: row.onboarding_status,
    representative_name: row.representative_name,
    representative_email: row.representative_email,
    representative_phone: row.representative_phone,
    created_at: row.created_at.toISOString(),
  };
}

/**
 * Retrieves the broker's dashboard metrics and status.
 */
export async function getBrokerDashboard(db: Db, user: AuthUser): Promise<BrokerDashboardDto> {
  const profile = await getBrokerProfile(db, user);

  const [activeRes, pendingRes, iposRes, ordersRes] = await Promise.all([
    db.query<{ count: string }>(
      `SELECT count(*)::bigint AS count
       FROM broker_client_relationships
       WHERE broker_id = $1 AND status = 'active'`,
      [profile.id],
    ),
    db.query<{ count: string }>(
      `SELECT count(*)::bigint AS count
       FROM broker_client_relationships
       WHERE broker_id = $1 AND status = 'pending'`,
      [profile.id],
    ),
    db.query<{ count: string }>(
      `SELECT count(*)::bigint AS count
       FROM ipos
       WHERE (status = 'open' OR status = 'approved') AND closes_at > now()`,
    ),
    db.query<{ count: string }>(
      `SELECT count(*)::bigint AS count
       FROM orders
       WHERE assisted_by_broker_id = $1`,
      [profile.id],
    ),
  ]);

  return {
    broker: profile,
    metrics: {
      total_active_clients: fromDb(activeRes.rows[0]?.count ?? '0'),
      pending_client_requests: fromDb(pendingRes.rows[0]?.count ?? '0'),
      available_ipos_count: fromDb(iposRes.rows[0]?.count ?? '0'),
      assisted_orders_count: fromDb(ordersRes.rows[0]?.count ?? '0'),
    },
  };
}

/**
 * Requests an authorized relationship with an investor by their email address.
 * Enforces:
 * 1. Broker onboarding must be approved.
 * 2. Investor must exist with role 'investor'.
 * 3. Prevents duplicate active or pending relationships.
 */
export async function requestClientRelationship(
  db: Db,
  user: AuthUser,
  input: {
    investor_email: string;
    relationship_type: 'advisory' | 'discretionary' | 'execution_only';
    notes?: string;
  },
  opts: { requestId: string },
): Promise<ClientRelationshipDto> {
  const profile = await getBrokerProfile(db, user);
  if (profile.onboarding_status !== 'approved') {
    throw Errors.forbidden(
      `Broker account must be approved before requesting client relationships (current status: ${profile.onboarding_status})`,
    );
  }

  // Look up investor
  const emailNorm = input.investor_email.trim().toLowerCase();
  const { rows: investorRows } = await db.query<{
    id: string;
    full_name: string;
    email: string;
    phone: string | null;
    verification_status: string;
    role: string;
  }>(
    `SELECT id, full_name, email, phone, verification_status, role
     FROM users
     WHERE LOWER(email) = $1`,
    [emailNorm],
  );

  const investor = investorRows[0];
  if (!investor || investor.role !== 'investor') {
    throw Errors.notFound('Eligible investor with this email was not found');
  }

  return db.tx(async (client) => {
    // Check existing relationship
    const existing = await client.query<{
      id: string;
      status: string;
    }>(
      `SELECT id, status
       FROM broker_client_relationships
       WHERE broker_id = $1 AND investor_id = $2
       FOR UPDATE`,
      [profile.id, investor.id],
    );

    let relId: string;
    const relStatus = 'pending' as const;

    if (existing.rows.length > 0) {
      const rel = existing.rows[0]!;
      if (rel.status === 'active') {
        throw Errors.conflict('An active authorized relationship with this investor already exists');
      }
      if (rel.status === 'pending') {
        throw Errors.conflict('A pending relationship request for this investor is already awaiting response');
      }

      // Re-open rejected or revoked relationship
      const updated = await client.query<{
        id: string;
        requested_at: Date;
        created_at: Date;
      }>(
        `UPDATE broker_client_relationships
         SET status = 'pending',
             relationship_type = $2,
             notes = $3,
             requested_by = 'broker',
             requested_at = now(),
             responded_at = null
         WHERE id = $1
         RETURNING id, requested_at, created_at`,
        [rel.id, input.relationship_type, input.notes ?? null],
      );
      relId = updated.rows[0]!.id;
    } else {
      const inserted = await client.query<{
        id: string;
        requested_at: Date;
        created_at: Date;
      }>(
        `INSERT INTO broker_client_relationships (
           broker_id, investor_id, relationship_type, status, notes, requested_by
         )
         VALUES ($1, $2, $3, 'pending', $4, 'broker')
         RETURNING id, requested_at, created_at`,
        [profile.id, investor.id, input.relationship_type, input.notes ?? null],
      );
      relId = inserted.rows[0]!.id;
    }

    await recordAudit(client, {
      actorUserId: user.id,
      actorRole: user.role,
      action: 'broker.client_request',
      targetType: 'relationship',
      targetId: relId,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: {
        broker_id: profile.id,
        investor_id: investor.id,
        relationship_type: input.relationship_type,
      },
    });

    return {
      id: relId,
      broker_id: profile.id,
      broker_firm_name: profile.firm_legal_name,
      investor_id: investor.id,
      investor_name: investor.full_name,
      investor_email: investor.email,
      investor_phone: investor.phone,
      investor_verification_status: investor.verification_status,
      relationship_type: input.relationship_type,
      status: relStatus,
      notes: input.notes ?? null,
      requested_by: 'broker',
      requested_at: new Date().toISOString(),
      responded_at: null,
    };
  });
}

/**
 * Lists the clients associated with the authenticated broker.
 */
export async function listBrokerClients(
  db: Db,
  user: AuthUser,
  statusFilter?: string,
): Promise<{ data: ClientRelationshipDto[] }> {
  const profile = await getBrokerProfile(db, user);

  const params: unknown[] = [profile.id];
  let filterSql = '';
  if (statusFilter) {
    params.push(statusFilter);
    filterSql = ` AND bcr.status = $${params.length}`;
  }

  const { rows } = await db.query<{
    id: string;
    broker_id: string;
    firm_legal_name: string;
    investor_id: string;
    investor_name: string;
    investor_email: string;
    investor_phone: string | null;
    investor_verification_status: string;
    relationship_type: 'advisory' | 'discretionary' | 'execution_only';
    status: 'pending' | 'active' | 'rejected' | 'revoked';
    notes: string | null;
    requested_by: 'broker' | 'investor';
    requested_at: Date;
    responded_at: Date | null;
  }>(
    `SELECT bcr.id, bcr.broker_id, b.legal_name AS firm_legal_name, bcr.investor_id,
            u.full_name AS investor_name, u.email AS investor_email,
            u.phone AS investor_phone, u.verification_status AS investor_verification_status,
            bcr.relationship_type, bcr.status, bcr.notes, bcr.requested_by,
            bcr.requested_at, bcr.responded_at
     FROM broker_client_relationships bcr
     JOIN brokers b ON b.id = bcr.broker_id
     JOIN users u ON u.id = bcr.investor_id
     WHERE bcr.broker_id = $1 ${filterSql}
     ORDER BY bcr.updated_at DESC`,
    params,
  );

  return {
    data: rows.map((r) => ({
      id: r.id,
      broker_id: r.broker_id,
      broker_firm_name: r.firm_legal_name,
      investor_id: r.investor_id,
      investor_name: r.investor_name,
      investor_email: r.investor_email,
      investor_phone: r.investor_phone,
      investor_verification_status: r.investor_verification_status,
      relationship_type: r.relationship_type,
      status: r.status,
      notes: r.notes,
      requested_by: r.requested_by,
      requested_at: r.requested_at.toISOString(),
      responded_at: r.responded_at ? r.responded_at.toISOString() : null,
    })),
  };
}

/**
 * Accesses private financial details and portfolio for an AUTHORIZED client.
 * Strictly verifies that the broker has an ACTIVE relationship with the client.
 */
export async function getAuthorizedClientDetail(
  db: Db,
  user: AuthUser,
  clientId: string,
): Promise<AuthorizedClientDetailDto> {
  const profile = await getBrokerProfile(db, user);

  const { rows } = await db.query<{
    id: string;
    broker_id: string;
    firm_legal_name: string;
    investor_id: string;
    investor_name: string;
    investor_email: string;
    investor_phone: string | null;
    investor_verification_status: string;
    relationship_type: 'advisory' | 'discretionary' | 'execution_only';
    status: 'pending' | 'active' | 'rejected' | 'revoked';
    notes: string | null;
    requested_by: 'broker' | 'investor';
    requested_at: Date;
    responded_at: Date | null;
  }>(
    `SELECT bcr.id, bcr.broker_id, b.legal_name AS firm_legal_name, bcr.investor_id,
            u.full_name AS investor_name, u.email AS investor_email,
            u.phone AS investor_phone, u.verification_status AS investor_verification_status,
            bcr.relationship_type, bcr.status, bcr.notes, bcr.requested_by,
            bcr.requested_at, bcr.responded_at
     FROM broker_client_relationships bcr
     JOIN brokers b ON b.id = bcr.broker_id
     JOIN users u ON u.id = bcr.investor_id
     WHERE bcr.broker_id = $1 AND bcr.investor_id = $2`,
    [profile.id, clientId],
  );

  const rel = rows[0];
  if (!rel) {
    throw Errors.notFound('Client relationship not found');
  }
  if (rel.status !== 'active') {
    throw Errors.forbidden(
      `Access denied. Client relationship is not active (current status: ${rel.status}). Explicit client authorization is required.`,
    );
  }

  // Fetch client wallet
  const walletRes = await db.query<{
    available_minor: string;
    reserved_minor: string;
    currency: string;
  }>(
    `SELECT available_minor, reserved_minor, currency
     FROM wallets
     WHERE user_id = $1`,
    [clientId],
  );

  const walletRow = walletRes.rows[0];
  const available = walletRow ? fromDb(walletRow.available_minor) : 0;
  const reserved = walletRow ? fromDb(walletRow.reserved_minor) : 0;
  const currency = walletRow?.currency ?? 'ETB';

  // Fetch client share holdings
  const holdingsRes = await db.query<{
    ipo_id: string;
    symbol: string;
    company_name: string;
    quantity: string;
    reserved_quantity: string;
  }>(
    `SELECT sh.ipo_id, i.symbol, c.legal_name AS company_name, sh.quantity, sh.reserved_quantity
     FROM share_holdings sh
     JOIN ipos i ON i.id = sh.ipo_id
     JOIN companies c ON c.id = i.company_id
     WHERE sh.investor_id = $1
     ORDER BY i.symbol ASC`,
    [clientId],
  );

  return {
    relationship: {
      id: rel.id,
      broker_id: rel.broker_id,
      broker_firm_name: rel.firm_legal_name,
      investor_id: rel.investor_id,
      investor_name: rel.investor_name,
      investor_email: rel.investor_email,
      investor_phone: rel.investor_phone,
      investor_verification_status: rel.investor_verification_status,
      relationship_type: rel.relationship_type,
      status: rel.status,
      notes: rel.notes,
      requested_by: rel.requested_by,
      requested_at: rel.requested_at.toISOString(),
      responded_at: rel.responded_at ? rel.responded_at.toISOString() : null,
    },
    client: {
      id: rel.investor_id,
      full_name: rel.investor_name,
      email: rel.investor_email,
      phone: rel.investor_phone,
      verification_status: rel.investor_verification_status,
    },
    wallet: {
      available_minor: available,
      reserved_minor: reserved,
      total_minor: available + reserved,
      currency,
    },
    holdings: holdingsRes.rows.map((h) => ({
      ipo_id: h.ipo_id,
      symbol: h.symbol,
      company_name: h.company_name,
      quantity: fromDb(h.quantity),
      reserved_quantity: fromDb(h.reserved_quantity),
    })),
  };
}

/**
 * Investor view: Lists all broker relationship requests and active relationships.
 */
export async function listInvestorBrokerRelationships(
  db: Db,
  user: AuthUser,
): Promise<{ data: ClientRelationshipDto[] }> {
  const { rows } = await db.query<{
    id: string;
    broker_id: string;
    firm_legal_name: string;
    investor_id: string;
    investor_name: string;
    investor_email: string;
    investor_phone: string | null;
    investor_verification_status: string;
    relationship_type: 'advisory' | 'discretionary' | 'execution_only';
    status: 'pending' | 'active' | 'rejected' | 'revoked';
    notes: string | null;
    requested_by: 'broker' | 'investor';
    requested_at: Date;
    responded_at: Date | null;
  }>(
    `SELECT bcr.id, bcr.broker_id, b.legal_name AS firm_legal_name, bcr.investor_id,
            u.full_name AS investor_name, u.email AS investor_email,
            u.phone AS investor_phone, u.verification_status AS investor_verification_status,
            bcr.relationship_type, bcr.status, bcr.notes, bcr.requested_by,
            bcr.requested_at, bcr.responded_at
     FROM broker_client_relationships bcr
     JOIN brokers b ON b.id = bcr.broker_id
     JOIN users u ON u.id = bcr.investor_id
     WHERE bcr.investor_id = $1
     ORDER BY bcr.updated_at DESC`,
    [user.id],
  );

  return {
    data: rows.map((r) => ({
      id: r.id,
      broker_id: r.broker_id,
      broker_firm_name: r.firm_legal_name,
      investor_id: r.investor_id,
      investor_name: r.investor_name,
      investor_email: r.investor_email,
      investor_phone: r.investor_phone,
      investor_verification_status: r.investor_verification_status,
      relationship_type: r.relationship_type,
      status: r.status,
      notes: r.notes,
      requested_by: r.requested_by,
      requested_at: r.requested_at.toISOString(),
      responded_at: r.responded_at ? r.responded_at.toISOString() : null,
    })),
  };
}

/**
 * Investor responds to or revokes a broker relationship.
 */
export async function respondToRelationship(
  db: Db,
  user: AuthUser,
  relationshipId: string,
  action: 'accept' | 'reject' | 'revoke',
  opts: { requestId: string },
): Promise<ClientRelationshipDto> {
  return db.tx(async (client) => {
    const { rows } = await client.query<{
      id: string;
      broker_id: string;
      investor_id: string;
      status: string;
      relationship_type: 'advisory' | 'discretionary' | 'execution_only';
      notes: string | null;
      requested_by: 'broker' | 'investor';
      requested_at: Date;
    }>(
      `SELECT id, broker_id, investor_id, status, relationship_type, notes, requested_by, requested_at
       FROM broker_client_relationships
       WHERE id = $1 FOR UPDATE`,
      [relationshipId],
    );

    const rel = rows[0];
    if (!rel) throw Errors.notFound('Relationship request not found');

    if (rel.investor_id !== user.id) {
      throw Errors.forbidden('You are not authorized to respond to this relationship request');
    }

    let nextStatus: 'active' | 'rejected' | 'revoked';
    if (action === 'accept') {
      if (rel.status !== 'pending') {
        throw Errors.conflict(`Cannot accept a relationship in status '${rel.status}'`);
      }
      nextStatus = 'active';
    } else if (action === 'reject') {
      if (rel.status !== 'pending') {
        throw Errors.conflict(`Cannot reject a relationship in status '${rel.status}'`);
      }
      nextStatus = 'rejected';
    } else {
      // revoke
      if (rel.status !== 'active') {
        throw Errors.conflict(`Cannot revoke a relationship that is not active (current: '${rel.status}')`);
      }
      nextStatus = 'revoked';
    }

    const respondedAt = new Date();
    await client.query(
      `UPDATE broker_client_relationships
       SET status = $2, responded_at = $3
       WHERE id = $1`,
      [relationshipId, nextStatus, respondedAt],
    );

    await recordAudit(client, {
      actorUserId: user.id,
      actorRole: user.role,
      action: `broker.relationship_${action}`,
      targetType: 'relationship',
      targetId: relationshipId,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: { from_status: rel.status, to_status: nextStatus },
    });

    const fullInfo = await client.query<{
      firm_legal_name: string;
      investor_name: string;
      investor_email: string;
      investor_phone: string | null;
      investor_verification_status: string;
    }>(
      `SELECT b.legal_name AS firm_legal_name, u.full_name AS investor_name, u.email AS investor_email,
              u.phone AS investor_phone, u.verification_status AS investor_verification_status
       FROM brokers b, users u
       WHERE b.id = $1 AND u.id = $2`,
      [rel.broker_id, rel.investor_id],
    );

    const info = fullInfo.rows[0]!;

    return {
      id: rel.id,
      broker_id: rel.broker_id,
      broker_firm_name: info.firm_legal_name,
      investor_id: rel.investor_id,
      investor_name: info.investor_name,
      investor_email: info.investor_email,
      investor_phone: info.investor_phone,
      investor_verification_status: info.investor_verification_status,
      relationship_type: rel.relationship_type,
      status: nextStatus,
      notes: rel.notes,
      requested_by: rel.requested_by,
      requested_at: rel.requested_at.toISOString(),
      responded_at: respondedAt.toISOString(),
    };
  });
}
