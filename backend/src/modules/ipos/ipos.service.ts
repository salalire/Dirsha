import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';
import type { Pagination } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import { CURRENCY, fromDb } from '../../lib/money.js';
import { recordAudit } from '../audit/audit.service.js';
import { documentStorage } from '../onboarding/document-storage.js';

export const IPO_STATUSES = [
  'draft',
  'submitted',
  'under_review',
  'approved',
  'open',
  'closed',
  'allocated',
  'listed',
  'rejected',
  'withdrawn',
] as const;
export type IpoStatus = (typeof IPO_STATUSES)[number];

/** Statuses any authenticated user may see. Everything else is private to the
 *  owning company and administrators (FR-IPO-07, FR-ONB-06). */
export const PUBLIC_STATUSES: IpoStatus[] = ['approved', 'open', 'closed', 'allocated', 'listed'];

/**
 * Computes authoritative effective IPO status based on scheduling window and administrative states.
 */
export function computeEffectiveIpoStatus(
  status: IpoStatus,
  opensAt: Date,
  closesAt: Date,
  now = new Date(),
): IpoStatus {
  // Terminal or administrative non-public states that override scheduling:
  if (
    status === 'closed' ||
    status === 'allocated' ||
    status === 'listed' ||
    status === 'rejected' ||
    status === 'withdrawn' ||
    status === 'draft' ||
    status === 'submitted' ||
    status === 'under_review'
  ) {
    return status;
  }

  // Active / Approved offerings follow date window rules:
  if (now >= closesAt) {
    return 'closed';
  }
  if (now >= opensAt) {
    return 'open';
  }
  return 'approved';
}

interface IpoRow {
  id: string;
  company_id: string;
  company_name: string;
  title: string;
  symbol: string;
  description: string | null;
  price_per_share_minor: string;
  total_shares: string;
  min_shares_per_subscription: string;
  max_shares_per_subscription: string | null;
  opens_at: Date;
  closes_at: Date;
  status: IpoStatus;
  created_at: Date;
  rejection_reason?: string | null;
  review_notes?: string | null;
}

export interface IpoDocumentDto {
  id: string;
  document_type: string;
  file_name: string;
  file_size_bytes: number;
  mime_type: string;
  review_status: string;
  created_at: string;
}

export interface IpoStatusHistoryDto {
  id: number;
  from_status: string | null;
  to_status: string;
  changed_by: string | null;
  reason: string | null;
  created_at: string;
}

export interface IpoDto {
  id: string;
  company_id: string;
  company_name: string;
  title: string;
  symbol: string;
  description: string | null;
  currency: typeof CURRENCY;
  price_per_share_minor: number;
  total_shares: number;
  min_shares_per_subscription: number;
  max_shares_per_subscription: number | null;
  opens_at: string;
  closes_at: string;
  status: IpoStatus;
  created_at: string;
  rejection_reason?: string | null;
  review_notes?: string | null;
  documents?: IpoDocumentDto[];
  history?: IpoStatusHistoryDto[];
}

export interface CompanyOfferingDto extends IpoDto {
  subscription_count: number;
  total_shares_subscribed: number;
  documents_count: number;
  latest_review_reason?: string | null;
}

function toDto(r: IpoRow): IpoDto {
  const effectiveStatus = computeEffectiveIpoStatus(r.status, r.opens_at, r.closes_at);
  return {
    id: r.id,
    company_id: r.company_id,
    company_name: r.company_name,
    title: r.title,
    symbol: r.symbol,
    description: r.description,
    currency: CURRENCY,
    price_per_share_minor: fromDb(r.price_per_share_minor),
    total_shares: fromDb(r.total_shares),
    min_shares_per_subscription: fromDb(r.min_shares_per_subscription),
    max_shares_per_subscription:
      r.max_shares_per_subscription === null ? null : fromDb(r.max_shares_per_subscription),
    opens_at: r.opens_at.toISOString(),
    closes_at: r.closes_at.toISOString(),
    status: effectiveStatus,
    created_at: r.created_at.toISOString(),
    rejection_reason: r.rejection_reason ?? null,
    review_notes: r.review_notes ?? null,
  };
}

const SELECT_IPO = `
  SELECT i.id, i.company_id, c.legal_name AS company_name, i.title, i.symbol, i.description,
         i.price_per_share_minor, i.total_shares, i.min_shares_per_subscription,
         i.max_shares_per_subscription, i.opens_at, i.closes_at, i.status, i.created_at,
         i.rejection_reason, i.review_notes
    FROM ipos i
    JOIN companies c ON c.id = i.company_id`;

/**
 * Visibility rule, enforced in SQL so a row the caller may not see can never be returned:
 *   admin        -> every IPO
 *   company_rep  -> public IPOs + every IPO of their own company
 *   everyone else-> public IPOs only
 * `params` is appended to; the returned fragment uses the next placeholders.
 */
function visibilityClause(user: AuthUser, params: unknown[]): string {
  if (user.role === 'admin') {
    return 'TRUE';
  }
  params.push(PUBLIC_STATUSES);
  const publicIdx = params.length;
  if (user.role === 'company_rep') {
    params.push(user.id);
    return `(i.status = ANY($${publicIdx}::text[]) OR c.owner_user_id = $${params.length})`;
  }
  return `i.status = ANY($${publicIdx}::text[])`;
}

export async function listIpos(
  db: Db,
  user: AuthUser,
  opts: { status?: IpoStatus | undefined; page: number; page_size: number },
): Promise<{ data: IpoDto[]; pagination: Pagination }> {
  const params: unknown[] = [];
  const where = [visibilityClause(user, params)];
  if (opts.status) {
    if (opts.status === 'open') {
      where.push(`(
        (i.status = 'open' OR i.status = 'approved') AND
        i.opens_at <= now() AND i.closes_at > now()
      )`);
    } else if (opts.status === 'approved') {
      where.push(`(
        i.status = 'approved' AND i.opens_at > now()
      )`);
    } else if (opts.status === 'closed') {
      where.push(`(
        i.status = 'closed' OR
        ((i.status = 'open' OR i.status = 'approved') AND i.closes_at <= now())
      )`);
    } else {
      params.push(opts.status);
      where.push(`i.status = $${params.length}`);
    }
  }
  const whereSql = where.join(' AND ');

  const total = fromDb(
    (
      await db.query<{ n: string }>(
        `SELECT count(*)::bigint AS n FROM ipos i JOIN companies c ON c.id = i.company_id
          WHERE ${whereSql}`,
        params,
      )
    ).rows[0]?.n,
  );

  const pageParams = [...params, opts.page_size, (opts.page - 1) * opts.page_size];
  const { rows } = await db.query<IpoRow>(
    `${SELECT_IPO}
      WHERE ${whereSql}
      ORDER BY i.opens_at DESC, i.id
      LIMIT $${pageParams.length - 1} OFFSET $${pageParams.length}`,
    pageParams,
  );

  return {
    data: rows.map(toDto),
    pagination: { page: opts.page, page_size: opts.page_size, total },
  };
}

/** Returns null when the IPO does not exist OR the caller may not see it. */
export async function getIpo(db: Db, user: AuthUser, id: string): Promise<IpoDto | null> {
  const params: unknown[] = [id];
  const vis = visibilityClause(user, params);
  const { rows } = await db.query<IpoRow>(`${SELECT_IPO} WHERE i.id = $1 AND ${vis}`, params);
  const row = rows[0];
  if (!row) return null;

  const dto = toDto(row);

  // If caller is admin or owning company rep, attach documents and history:
  let isOwnerOrAdmin = user.role === 'admin';
  if (!isOwnerOrAdmin && user.role === 'company_rep') {
    const ownerCheck = await db.query(
      'SELECT 1 FROM companies WHERE id = $1 AND owner_user_id = $2',
      [row.company_id, user.id],
    );
    isOwnerOrAdmin = ownerCheck.rows.length > 0;
  }

  if (isOwnerOrAdmin) {
    dto.documents = await listIpoDocuments(db, user, id);
    dto.history = await getIpoHistory(db, user, id);
  }

  return dto;
}

// ── Company IPO Management ──────────────────────────────────────────────────

export interface CreateIpoInput {
  title: string;
  symbol: string;
  description?: string | null;
  price_per_share_minor: number;
  total_shares: number;
  min_shares_per_subscription?: number;
  max_shares_per_subscription?: number | null;
  opens_at: string;
  closes_at: string;
  company_id?: string;
}

export interface UpdateIpoInput {
  title?: string;
  symbol?: string;
  description?: string | null;
  price_per_share_minor?: number;
  total_shares?: number;
  min_shares_per_subscription?: number;
  max_shares_per_subscription?: number | null;
  opens_at?: string;
  closes_at?: string;
}

export async function createIpoDraft(
  db: Db,
  user: AuthUser,
  input: CreateIpoInput,
  opts: { requestId: string },
): Promise<IpoDto> {
  if (user.role !== 'company_rep' && user.role !== 'admin') {
    throw Errors.forbidden('Only company representatives can create IPO offerings');
  }

  let companyId: string;
  if (user.role === 'company_rep') {
    const compRes = await db.query<{ id: string; onboarding_status: string }>(
      'SELECT id, onboarding_status FROM companies WHERE owner_user_id = $1',
      [user.id],
    );
    const company = compRes.rows[0];
    if (!company) {
      throw Errors.forbidden(
        'You must register and complete company onboarding before creating an IPO offering',
      );
    }
    if (company.onboarding_status !== 'approved') {
      throw Errors.forbidden(
        `Company onboarding application must be approved before creating an IPO offering (current status: ${company.onboarding_status})`,
      );
    }
    companyId = company.id;
  } else {
    if (input.company_id) {
      companyId = input.company_id;
    } else {
      const compRes = await db.query<{ id: string }>(
        "SELECT id FROM companies WHERE onboarding_status = 'approved' LIMIT 1",
      );
      if (!compRes.rows[0]) {
        throw Errors.conflict('No approved company available to attach IPO');
      }
      companyId = compRes.rows[0].id;
    }
  }

  const symbolUpper = input.symbol.trim().toUpperCase();
  const existingSymbol = await db.query('SELECT id FROM ipos WHERE UPPER(symbol) = $1', [symbolUpper]);
  if (existingSymbol.rows.length > 0) {
    throw Errors.conflict(`An IPO offering with symbol '${symbolUpper}' already exists`);
  }

  const opensAt = new Date(input.opens_at);
  const closesAt = new Date(input.closes_at);
  if (isNaN(opensAt.getTime()) || isNaN(closesAt.getTime())) {
    throw Errors.validation({}, 'Invalid date format');
  }
  if (closesAt <= opensAt) {
    throw Errors.validation({ field: 'closes_at' }, 'closes_at must be strictly after opens_at');
  }

  const minShares = input.min_shares_per_subscription ?? 1;
  const maxShares = input.max_shares_per_subscription ?? null;
  if (maxShares !== null && maxShares < minShares) {
    throw Errors.validation(
      { field: 'max_shares_per_subscription' },
      'max_shares_per_subscription must be >= min_shares_per_subscription',
    );
  }
  if (input.total_shares < minShares) {
    throw Errors.validation(
      { field: 'total_shares' },
      'total_shares must be >= min_shares_per_subscription',
    );
  }

  return db.tx(async (client) => {
    const insertRes = await client.query<IpoRow>(
      `INSERT INTO ipos (
        company_id, title, symbol, description, price_per_share_minor,
        total_shares, min_shares_per_subscription, max_shares_per_subscription,
        opens_at, closes_at, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'draft')
      RETURNING id, company_id, (SELECT legal_name FROM companies WHERE id = $1) AS company_name,
                title, symbol, description, price_per_share_minor, total_shares,
                min_shares_per_subscription, max_shares_per_subscription,
                opens_at, closes_at, status, created_at, rejection_reason, review_notes`,
      [
        companyId,
        input.title.trim(),
        symbolUpper,
        input.description?.trim() || null,
        input.price_per_share_minor,
        input.total_shares,
        minShares,
        maxShares,
        opensAt,
        closesAt,
      ],
    );
    const row = insertRes.rows[0];
    if (!row) throw Errors.notFound('Failed to create IPO');

    await client.query(
      `INSERT INTO ipo_status_history (ipo_id, from_status, to_status, changed_by, reason)
       VALUES ($1, null, 'draft', $2, 'IPO draft offering created')`,
      [row.id, user.id],
    );

    await recordAudit(client, {
      actorUserId: user.id,
      actorRole: user.role,
      action: 'ipo.create_draft',
      targetType: 'ipo',
      targetId: row.id,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: { symbol: symbolUpper, title: input.title },
    });

    return toDto(row);
  });
}

export async function updateIpoDraft(
  db: Db,
  user: AuthUser,
  ipoId: string,
  input: UpdateIpoInput,
  opts: { requestId: string },
): Promise<IpoDto> {
  return db.tx(async (client) => {
    const locked = (
      await client.query<{
        id: string;
        company_id: string;
        owner_user_id: string;
        status: IpoStatus;
        symbol: string;
        opens_at: Date;
        closes_at: Date;
        min_shares_per_subscription: string;
        max_shares_per_subscription: string | null;
        total_shares: string;
      }>(
        `SELECT i.id, i.company_id, c.owner_user_id, i.status, i.symbol,
                i.opens_at, i.closes_at, i.min_shares_per_subscription,
                i.max_shares_per_subscription, i.total_shares
         FROM ipos i
         JOIN companies c ON c.id = i.company_id
         WHERE i.id = $1 FOR UPDATE`,
        [ipoId],
      )
    ).rows[0];

    if (!locked) throw Errors.notFound('IPO not found');
    if (user.role !== 'admin' && locked.owner_user_id !== user.id) {
      throw Errors.forbidden('You do not have permission to modify this IPO');
    }
    if (locked.status !== 'draft') {
      throw Errors.conflict(
        `Cannot modify an IPO currently in status '${locked.status}'. Only draft offerings can be edited.`,
      );
    }

    let symbolUpper = locked.symbol;
    if (input.symbol && input.symbol.trim().toUpperCase() !== locked.symbol) {
      symbolUpper = input.symbol.trim().toUpperCase();
      const existing = await client.query(
        'SELECT id FROM ipos WHERE UPPER(symbol) = $1 AND id <> $2',
        [symbolUpper, ipoId],
      );
      if (existing.rows.length > 0) {
        throw Errors.conflict(`An IPO with symbol '${symbolUpper}' already exists`);
      }
    }

    const opensAt = input.opens_at ? new Date(input.opens_at) : locked.opens_at;
    const closesAt = input.closes_at ? new Date(input.closes_at) : locked.closes_at;
    if (closesAt <= opensAt) {
      throw Errors.validation({ field: 'closes_at' }, 'closes_at must be strictly after opens_at');
    }

    const minShares = input.min_shares_per_subscription ?? fromDb(locked.min_shares_per_subscription);
    const maxShares =
      input.max_shares_per_subscription !== undefined
        ? input.max_shares_per_subscription
        : locked.max_shares_per_subscription
        ? fromDb(locked.max_shares_per_subscription)
        : null;

    if (maxShares !== null && maxShares < minShares) {
      throw Errors.validation(
        { field: 'max_shares_per_subscription' },
        'max_shares_per_subscription must be >= min_shares_per_subscription',
      );
    }

    const res = await client.query<IpoRow>(
      `UPDATE ipos
       SET title = COALESCE($2, title),
           symbol = $3,
           description = CASE WHEN $4::text IS NOT NULL THEN $4 ELSE description END,
           price_per_share_minor = COALESCE($5, price_per_share_minor),
           total_shares = COALESCE($6, total_shares),
           min_shares_per_subscription = $7,
           max_shares_per_subscription = $8,
           opens_at = $9,
           closes_at = $10
       WHERE id = $1
       RETURNING id, company_id, (SELECT legal_name FROM companies WHERE id = ipos.company_id) AS company_name,
                 title, symbol, description, price_per_share_minor, total_shares,
                 min_shares_per_subscription, max_shares_per_subscription,
                 opens_at, closes_at, status, created_at, rejection_reason, review_notes`,
      [
        ipoId,
        input.title?.trim() ?? null,
        symbolUpper,
        input.description !== undefined ? input.description?.trim() ?? null : null,
        input.price_per_share_minor ?? null,
        input.total_shares ?? null,
        minShares,
        maxShares,
        opensAt,
        closesAt,
      ],
    );

    await recordAudit(client, {
      actorUserId: user.id,
      actorRole: user.role,
      action: 'ipo.update_draft',
      targetType: 'ipo',
      targetId: ipoId,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: { symbol: symbolUpper },
    });

    const updatedRow = res.rows[0];
    if (!updatedRow) throw Errors.notFound('IPO not found');
    return toDto(updatedRow);
  });
}

export async function submitIpo(
  db: Db,
  user: AuthUser,
  ipoId: string,
  opts: { notes?: string; requestId: string },
): Promise<IpoDto> {
  return db.tx(async (client) => {
    const locked = (
      await client.query<{
        id: string;
        company_id: string;
        owner_user_id: string;
        onboarding_status: string;
        status: IpoStatus;
        title: string;
        symbol: string;
      }>(
        `SELECT i.id, i.company_id, c.owner_user_id, c.onboarding_status, i.status, i.title, i.symbol
         FROM ipos i
         JOIN companies c ON c.id = i.company_id
         WHERE i.id = $1 FOR UPDATE`,
        [ipoId],
      )
    ).rows[0];

    if (!locked) throw Errors.notFound('IPO not found');
    if (user.role !== 'admin' && locked.owner_user_id !== user.id) {
      throw Errors.forbidden('You do not have permission to submit this IPO');
    }
    if (locked.onboarding_status !== 'approved') {
      throw Errors.forbidden(
        'Company onboarding must be approved to submit an IPO for review',
      );
    }
    if (locked.status !== 'draft') {
      throw Errors.conflict(
        `Cannot submit an IPO in '${locked.status}' status. Only draft offerings can be submitted.`,
      );
    }

    const nextStatus = 'submitted';
    const res = await client.query<IpoRow>(
      `UPDATE ipos
       SET status = $2, rejection_reason = null
       WHERE id = $1
       RETURNING id, company_id, (SELECT legal_name FROM companies WHERE id = ipos.company_id) AS company_name,
                 title, symbol, description, price_per_share_minor, total_shares,
                 min_shares_per_subscription, max_shares_per_subscription,
                 opens_at, closes_at, status, created_at, rejection_reason, review_notes`,
      [ipoId, nextStatus],
    );

    await client.query(
      `INSERT INTO ipo_status_history (ipo_id, from_status, to_status, changed_by, reason)
       VALUES ($1, 'draft', $2, $3, $4)`,
      [ipoId, nextStatus, user.id, opts.notes ?? 'Submitted for administrative compliance review'],
    );

    await recordAudit(client, {
      actorUserId: user.id,
      actorRole: user.role,
      action: 'ipo.submit',
      targetType: 'ipo',
      targetId: ipoId,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: { from_status: 'draft', to_status: nextStatus },
    });

    const submittedRow = res.rows[0];
    if (!submittedRow) throw Errors.notFound('IPO not found');
    return toDto(submittedRow);
  });
}

export async function listCompanyOfferings(
  db: Db,
  user: AuthUser,
): Promise<{ data: CompanyOfferingDto[] }> {
  if (user.role !== 'company_rep' && user.role !== 'admin') {
    throw Errors.forbidden('Only company representatives and admins can view company offerings');
  }

  let companyFilter = '';
  const params: unknown[] = [];
  if (user.role === 'company_rep') {
    params.push(user.id);
    companyFilter = 'WHERE c.owner_user_id = $1';
  }

  const query = `
    SELECT i.id, i.company_id, c.legal_name AS company_name, i.title, i.symbol, i.description,
           i.price_per_share_minor, i.total_shares, i.min_shares_per_subscription,
           i.max_shares_per_subscription, i.opens_at, i.closes_at, i.status, i.created_at,
           i.rejection_reason, i.review_notes,
           COALESCE((
             SELECT count(*)::bigint FROM subscriptions s
             WHERE s.ipo_id = i.id AND s.status IN ('reserved', 'allocated', 'partially_allocated')
           ), 0) AS subscription_count,
           COALESCE((
             SELECT sum(s.quantity)::bigint FROM subscriptions s
             WHERE s.ipo_id = i.id AND s.status IN ('reserved', 'allocated', 'partially_allocated')
           ), 0) AS total_shares_subscribed,
           COALESCE((
             SELECT count(*)::bigint FROM supporting_documents d
             WHERE d.entity_type = 'ipo' AND d.entity_id = i.id
           ), 0) AS documents_count,
           (
             SELECT h.reason FROM ipo_status_history h
             WHERE h.ipo_id = i.id AND h.reason IS NOT NULL
             ORDER BY h.created_at DESC LIMIT 1
           ) AS latest_review_reason
    FROM ipos i
    JOIN companies c ON c.id = i.company_id
    ${companyFilter}
    ORDER BY i.created_at DESC, i.id DESC
  `;

  const { rows } = await db.query<
    IpoRow & {
      subscription_count: string;
      total_shares_subscribed: string;
      documents_count: string;
      latest_review_reason: string | null;
    }
  >(query, params);

  return {
    data: rows.map((r) => {
      const base = toDto(r);
      return {
        ...base,
        subscription_count: fromDb(r.subscription_count),
        total_shares_subscribed: fromDb(r.total_shares_subscribed),
        documents_count: fromDb(r.documents_count),
        latest_review_reason: r.latest_review_reason,
      };
    }),
  };
}

export async function uploadIpoDocument(
  db: Db,
  user: AuthUser,
  ipoId: string,
  doc: {
    document_type: string;
    file_name: string;
    mime_type: string;
    content: string; // Base64
  },
  opts: { requestId: string },
) {
  const ipoRes = await db.query<{ id: string; owner_user_id: string; status: IpoStatus }>(
    `SELECT i.id, c.owner_user_id, i.status
     FROM ipos i
     JOIN companies c ON c.id = i.company_id
     WHERE i.id = $1`,
    [ipoId],
  );
  const ipo = ipoRes.rows[0];
  if (!ipo) throw Errors.notFound('IPO not found');

  if (user.role !== 'admin' && ipo.owner_user_id !== user.id) {
    throw Errors.forbidden('You do not have permission to upload documents for this IPO');
  }
  if (ipo.status !== 'draft' && ipo.status !== 'submitted' && ipo.status !== 'under_review') {
    throw Errors.conflict(`Documents cannot be uploaded when IPO is in status '${ipo.status}'`);
  }

  const stored = await documentStorage.saveFile({
    fileName: doc.file_name,
    mimeType: doc.mime_type,
    content: doc.content,
  });

  const insertRes = await db.query(
    `INSERT INTO supporting_documents (
      owner_user_id, entity_type, entity_id, document_type,
      file_name, file_size_bytes, mime_type, storage_key, review_status
    ) VALUES ($1, 'ipo', $2, $3, $4, $5, $6, $7, 'pending')
    RETURNING id, document_type, file_name, file_size_bytes, mime_type, review_status, created_at`,
    [
      user.id,
      ipo.id,
      doc.document_type,
      stored.fileName,
      stored.fileSizeBytes,
      stored.mimeType,
      stored.storageKey,
    ],
  );

  await recordAudit(db, {
    actorUserId: user.id,
    actorRole: user.role,
    action: 'ipo.upload_document',
    targetType: 'ipo',
    targetId: ipo.id,
    outcome: 'success',
    requestId: opts.requestId,
    metadata: { document_type: doc.document_type, file_name: stored.fileName },
  });

  return insertRes.rows[0];
}

export async function listIpoDocuments(
  db: Db,
  user: AuthUser,
  ipoId: string,
): Promise<IpoDocumentDto[]> {
  const ipoRes = await db.query<{ id: string; owner_user_id: string; status: IpoStatus }>(
    `SELECT i.id, c.owner_user_id, i.status
     FROM ipos i
     JOIN companies c ON c.id = i.company_id
     WHERE i.id = $1`,
    [ipoId],
  );
  const ipo = ipoRes.rows[0];
  if (!ipo) throw Errors.notFound('IPO not found');

  const isOwnerOrAdmin = user.role === 'admin' || ipo.owner_user_id === user.id;
  if (!isOwnerOrAdmin && !PUBLIC_STATUSES.includes(ipo.status)) {
    throw Errors.forbidden('You do not have permission to view documents for this IPO');
  }

  const { rows } = await db.query<{
    id: string;
    document_type: string;
    file_name: string;
    file_size_bytes: string;
    mime_type: string;
    review_status: string;
    created_at: Date;
  }>(
    `SELECT id, document_type, file_name, file_size_bytes, mime_type, review_status, created_at
     FROM supporting_documents
     WHERE entity_type = 'ipo' AND entity_id = $1
     ORDER BY created_at ASC`,
    [ipo.id],
  );

  return rows.map((r) => ({
    id: r.id,
    document_type: r.document_type,
    file_name: r.file_name,
    file_size_bytes: fromDb(r.file_size_bytes),
    mime_type: r.mime_type,
    review_status: r.review_status,
    created_at: r.created_at.toISOString(),
  }));
}

export async function getIpoDocumentFile(db: Db, user: AuthUser, ipoId: string, docId: string) {
  const docRes = await db.query(
    "SELECT * FROM supporting_documents WHERE id = $1 AND entity_type = 'ipo' AND entity_id = $2",
    [docId, ipoId],
  );
  const doc = docRes.rows[0];
  if (!doc) throw Errors.notFound('Document not found');

  if (doc.owner_user_id !== user.id && user.role !== 'admin') {
    throw Errors.forbidden('You do not have permission to download this document');
  }

  const buffer = await documentStorage.readFile(doc.storage_key);
  return {
    buffer,
    mimeType: doc.mime_type,
    fileName: doc.file_name,
  };
}

export async function deleteIpoDocument(
  db: Db,
  user: AuthUser,
  ipoId: string,
  docId: string,
  opts: { requestId: string },
) {
  const ipoRes = await db.query<{ id: string; owner_user_id: string; status: IpoStatus }>(
    `SELECT i.id, c.owner_user_id, i.status
     FROM ipos i
     JOIN companies c ON c.id = i.company_id
     WHERE i.id = $1`,
    [ipoId],
  );
  const ipo = ipoRes.rows[0];
  if (!ipo) throw Errors.notFound('IPO not found');

  if (user.role !== 'admin' && ipo.owner_user_id !== user.id) {
    throw Errors.forbidden('You do not have permission to delete documents for this IPO');
  }
  if (ipo.status !== 'draft') {
    throw Errors.conflict('Documents can only be deleted while the offering is in draft status');
  }

  const docRes = await db.query(
    "SELECT * FROM supporting_documents WHERE id = $1 AND entity_type = 'ipo' AND entity_id = $2",
    [docId, ipoId],
  );
  const doc = docRes.rows[0];
  if (!doc) throw Errors.notFound('Document not found');

  await documentStorage.deleteFile(doc.storage_key);
  await db.query('DELETE FROM supporting_documents WHERE id = $1', [docId]);

  await recordAudit(db, {
    actorUserId: user.id,
    actorRole: user.role,
    action: 'ipo.delete_document',
    targetType: 'ipo',
    targetId: ipoId,
    outcome: 'success',
    requestId: opts.requestId,
    metadata: { document_id: docId, file_name: doc.file_name },
  });

  return { success: true };
}

export async function getIpoHistory(
  db: Db,
  user: AuthUser,
  ipoId: string,
): Promise<IpoStatusHistoryDto[]> {
  const ipoRes = await db.query<{ id: string; owner_user_id: string }>(
    `SELECT i.id, c.owner_user_id
     FROM ipos i
     JOIN companies c ON c.id = i.company_id
     WHERE i.id = $1`,
    [ipoId],
  );
  const ipo = ipoRes.rows[0];
  if (!ipo) throw Errors.notFound('IPO not found');
  if (user.role !== 'admin' && ipo.owner_user_id !== user.id) {
    throw Errors.forbidden();
  }

  const { rows } = await db.query<{
    id: string;
    from_status: string | null;
    to_status: string;
    changed_by: string | null;
    reason: string | null;
    created_at: Date;
  }>(
    `SELECT id, from_status, to_status, changed_by, reason, created_at
     FROM ipo_status_history
     WHERE ipo_id = $1
     ORDER BY created_at ASC`,
    [ipoId],
  );

  return rows.map((r) => ({
    id: fromDb(r.id),
    from_status: r.from_status,
    to_status: r.to_status,
    changed_by: r.changed_by,
    reason: r.reason,
    created_at: r.created_at.toISOString(),
  }));
}
