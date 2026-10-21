import { Router } from 'express';
import type { Db } from '../../db/pool.js';

/**
 * GET /health: liveness + database reachability for deployment monitoring (NFR-REL-03).
 * Deliberately returns no version, configuration, host names or error details.
 */
export function healthRouter(db: Db): Router {
  const router = Router();
  router.get('/', async (_req, res) => {
    const dbUp = await db.ping();
    res.status(dbUp ? 200 : 503).json({
      status: dbUp ? 'ok' : 'degraded',
      checks: { database: dbUp ? 'up' : 'down' },
      timestamp: new Date().toISOString(),
    });
  });
  return router;
}
