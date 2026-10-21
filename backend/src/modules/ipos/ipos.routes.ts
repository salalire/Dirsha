import { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { paginationSchema, parseWith, uuidSchema } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import { getIpo, IPO_STATUSES, listIpos } from './ipos.service.js';

const listQuerySchema = paginationSchema.extend({
  status: z.enum(IPO_STATUSES).optional(),
});

export function iposRouter(deps: AppDeps): Router {
  const router = Router();
  router.use(createAuthenticate(deps));

  router.get('/', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const q = parseWith(listQuerySchema, req.query);
    res.json(await listIpos(deps.db, req.user, q));
  });

  router.get('/:id', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const ipo = await getIpo(deps.db, req.user, id);
    // Same response whether it does not exist or is not visible to the caller.
    if (!ipo) throw Errors.notFound('IPO not found');
    res.json({ data: ipo });
  });

  return router;
}
