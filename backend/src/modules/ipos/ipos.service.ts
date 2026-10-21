import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';
import type { Pagination } from '../../http/validate.js';
import { CURRENCY, fromDb } from '../../lib/money.js';

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
const PUBLIC_STATUSES: IpoStatus[] = ['open', 'closed', 'allocated', 'listed'];

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
}

function toDto(r: IpoRow): IpoDto {
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
    status: r.status,
    created_at: r.created_at.toISOString(),
  };
}

const SELECT_IPO = `
  SELECT i.id, i.company_id, c.legal_name AS company_name, i.title, i.symbol, i.description,
         i.price_per_share_minor, i.total_shares, i.min_shares_per_subscription,
         i.max_shares_per_subscription, i.opens_at, i.closes_at, i.status, i.created_at
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
    params.push(opts.status);
    where.push(`i.status = $${params.length}`);
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
  return row ? toDto(row) : null;
}
