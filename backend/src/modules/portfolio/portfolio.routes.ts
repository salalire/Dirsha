import { Router } from 'express';
import { createAuthenticate, requireRole } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { Errors } from '../../lib/errors.js';
import { getInvestorPortfolio } from './portfolio.service.js';

export function portfolioRouter(deps: AppDeps): Router {
  const router = Router();
  router.use(createAuthenticate(deps));

  // GET /portfolio: Investors retrieve their holdings and portfolio valuation (FR-PORT-01..04)
  router.get('/', requireRole('investor'), async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const portfolio = await getInvestorPortfolio(deps.db, req.user);
    res.json({ data: portfolio });
  });

  return router;
}
