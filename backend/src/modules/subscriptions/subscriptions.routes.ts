import { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate, requireRole } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import {
  idempotencyKeySchema,
  paginationSchema,
  parseWith,
  uuidSchema,
} from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import {
  createSubscription,
  getSubscription,
  listSubscriptions,
  SUBSCRIPTION_STATUSES,
} from './subscriptions.service.js';

const createSubscriptionSchema = z.strictObject({
  ipo_id: uuidSchema,
  quantity: z.number().int().min(1, 'Quantity must be at least 1 share'),
});

const listSubscriptionsQuerySchema = paginationSchema.extend({
  ipo_id: uuidSchema.optional(),
  status: z.enum(SUBSCRIPTION_STATUSES).optional(),
});

export function subscriptionsRouter(deps: AppDeps): Router {
  const router = Router();
  router.use(createAuthenticate(deps));

  // POST /subscriptions: Investors create a subscription and reserve funds atomically
  router.post('/', requireRole('investor'), async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const key = parseWith(idempotencyKeySchema, req.header('idempotency-key'));
    const body = parseWith(createSubscriptionSchema, req.body);

    const result = await createSubscription(deps.db, req.user, {
      ipoId: body.ipo_id,
      quantity: body.quantity,
      idempotencyKey: key,
      requestId: req.requestId,
    });

    res
      .status(result.replayed ? 200 : 201)
      .set('Idempotent-Replay', String(result.replayed))
      .json({ data: result.subscription });
  });

  // GET /subscriptions: Investors see their own; Admins see all
  router.get('/', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const q = parseWith(listSubscriptionsQuerySchema, req.query);
    res.json(await listSubscriptions(deps.db, req.user, q));
  });

  // GET /subscriptions/:id: Fetch single subscription
  router.get('/:id', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const sub = await getSubscription(deps.db, req.user, id);
    if (!sub) throw Errors.notFound('Subscription not found');
    res.json({ data: sub });
  });

  return router;
}
