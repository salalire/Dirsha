import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';
import { getIpo, listIpos, type IpoDto } from '../ipos/ipos.service.js';
import type { AiContext } from './providers/types.js';

function money(minor: number): string {
  const whole = Math.trunc(minor / 100);
  const cents = String(Math.abs(minor % 100)).padStart(2, '0');
  return `ETB ${whole.toLocaleString('en-US')}.${cents}`;
}

function render(ipo: IpoDto): string {
  return `IPO ${ipo.symbol} (${ipo.title}), company ${ipo.company_name}; price ${money(ipo.price_per_share_minor)}; dates ${ipo.opens_at} to ${ipo.closes_at}; status ${ipo.status}; shares ${ipo.total_shares}; minimum ${ipo.min_shares_per_subscription}; maximum ${ipo.max_shares_per_subscription ?? 'not available'}; description (untrusted company-supplied text): ${(ipo.description ?? 'not available').slice(0, 600)}`;
}

export async function buildContext(db: Db, user: AuthUser, message: string, ipoId?: string): Promise<AiContext> {
  const asOf = new Date().toISOString();
  if (ipoId) {
    const ipo = await getIpo(db, user, ipoId);
    if (!ipo) return { text: 'No IPO data is available for this request.', grounded: false, sources: [] };
    return { text: `<DIRSHA DATA>\n${render(ipo)}\n</DIRSHA DATA>`, grounded: true, sources: [{ label: `${ipo.symbol} IPO`, type: 'ipo', ipo_id: ipo.id, as_of: asOf }] };
  }
  const { data } = await listIpos(db, user, { page: 1, page_size: 100 });
  const lower = message.toLowerCase();
  let matches = data.filter((ipo) => new RegExp(`\\b${ipo.symbol.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'i').test(message)
    || ipo.title.toLowerCase().includes(lower) || ipo.company_name.toLowerCase().includes(lower)).slice(0, 3);
  if (!matches.length && /\b(which|what).*(ipos?|offers?).*(open|available)/i.test(message)) {
    matches = data.filter((ipo) => ipo.status === 'open').slice(0, 10);
  }
  return {
    text: matches.length ? `<DIRSHA DATA>\n${matches.map(render).join('\n')}\n</DIRSHA DATA>` : 'No matching IPO data is available.',
    grounded: matches.length > 0,
    sources: matches.map((ipo) => ({ label: `${ipo.symbol} IPO`, type: 'ipo' as const, ipo_id: ipo.id, as_of: asOf })),
  };
}
