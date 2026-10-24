import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';
import { fromDb } from '../../lib/money.js';

export interface HoldingDto {
  ipo_id: string;
  subscription_id: string;
  company_id: string;
  company_name: string;
  symbol: string;
  title: string;
  allocated_quantity: number;
  price_per_share_minor: number;
  total_value_minor: number;
  currency: string;
  valuation_source: string;
  allocated_at: string;
}

export interface PortfolioSummaryDto {
  total_positions: number;
  total_shares: number;
  total_valuation_minor: number;
  currency: string;
  valuation_source: string;
  as_of: string;
}

export interface PortfolioResponseDto {
  summary: PortfolioSummaryDto;
  holdings: HoldingDto[];
}

interface HoldingRow {
  subscription_id: string;
  ipo_id: string;
  allocated_quantity: string;
  allocated_at: Date;
  company_id: string;
  title: string;
  symbol: string;
  price_per_share_minor: string;
  company_name: string;
}

/**
 * Returns the investor's current portfolio holdings (FR-PORT-01..04).
 *
 * Sourced directly from authoritative settled/allocated subscriptions.
 * Distinguishes allocated shares from pending subscriptions and provides
 * valuation based on the IPO offering price.
 */
export async function getInvestorPortfolio(
  db: Db,
  user: AuthUser,
): Promise<PortfolioResponseDto> {
  const { rows } = await db.query<HoldingRow>(
    `SELECT s.id AS subscription_id,
            s.ipo_id,
            s.allocated_quantity,
            s.updated_at AS allocated_at,
            i.company_id,
            i.title,
            i.symbol,
            i.price_per_share_minor,
            COALESCE(c.trade_name, c.legal_name) AS company_name
     FROM subscriptions s
     JOIN ipos i ON i.id = s.ipo_id
     JOIN companies c ON c.id = i.company_id
     WHERE s.investor_id = $1
       AND s.status IN ('allocated', 'partially_allocated')
       AND s.allocated_quantity > 0
     ORDER BY s.updated_at DESC, s.id DESC`,
    [user.id],
  );

  let totalShares = 0;
  let totalValuationMinor = 0;

  const holdings: HoldingDto[] = rows.map((r) => {
    const qty = fromDb(r.allocated_quantity);
    const price = fromDb(r.price_per_share_minor);
    const val = qty * price;
    totalShares += qty;
    totalValuationMinor += val;

    return {
      ipo_id: r.ipo_id,
      subscription_id: r.subscription_id,
      company_id: r.company_id,
      company_name: r.company_name,
      symbol: r.symbol,
      title: r.title,
      allocated_quantity: qty,
      price_per_share_minor: price,
      total_value_minor: val,
      currency: 'ETB',
      valuation_source: 'ipo_offering_price',
      allocated_at: r.allocated_at.toISOString(),
    };
  });

  return {
    summary: {
      total_positions: holdings.length,
      total_shares: totalShares,
      total_valuation_minor: totalValuationMinor,
      currency: 'ETB',
      valuation_source: 'ipo_offering_price',
      as_of: new Date().toISOString(),
    },
    holdings,
  };
}
