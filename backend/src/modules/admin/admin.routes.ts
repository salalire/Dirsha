import { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate, requireRole } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { paginationSchema, parseWith, uuidSchema } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import {
  allocateIpo,
  approveIpo,
  closeIpo,
  listAllUsers,
  listAuditEvents,
  rejectIpo,
} from './admin.service.js';

const auditQuerySchema = paginationSchema.extend({
  actor_user_id: uuidSchema.optional(),
  action: z.string().optional(),
});

const usersQuerySchema = paginationSchema.extend({
  role: z.enum(['investor', 'company_rep', 'broker', 'admin']).optional(),
  account_status: z.enum(['active', 'suspended']).optional(),
});

const approveIpoSchema = z.strictObject({
  notes: z.string().max(1000).optional(),
});

const rejectIpoSchema = z.strictObject({
  reason: z.string().min(3).max(1000),
});

const closeIpoSchema = z.strictObject({
  reason: z.string().max(1000).optional(),
});

export function adminRouter(deps: AppDeps): Router {
  const router = Router();
  // All admin routes require authentication and admin role (FR-ADM-02, FR-ADM-04)
  router.use(createAuthenticate(deps), requireRole('admin'));

  // GET /admin/audit
  router.get('/audit', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const q = parseWith(auditQuerySchema, req.query);
    res.json(await listAuditEvents(deps.db, q));
  });

  // GET /admin/users
  router.get('/users', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const q = parseWith(usersQuerySchema, req.query);
    res.json(await listAllUsers(deps.db, q));
  });

  // POST /admin/ipos/:id/approve
  router.post('/ipos/:id/approve', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(approveIpoSchema, req.body ?? {});
    const result = await approveIpo(deps.db, req.user, id, {
      notes: body.notes,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // POST /admin/ipos/:id/reject
  router.post('/ipos/:id/reject', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(rejectIpoSchema, req.body);
    const result = await rejectIpo(deps.db, req.user, id, {
      reason: body.reason,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // POST /admin/ipos/:id/close
  router.post('/ipos/:id/close', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(closeIpoSchema, req.body ?? {});
    const result = await closeIpo(deps.db, req.user, id, {
      reason: body.reason,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // POST /admin/ipos/:id/allocate
  router.post('/ipos/:id/allocate', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const result = await allocateIpo(deps.db, req.user, id, {
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  return router;
}
