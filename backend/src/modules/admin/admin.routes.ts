import { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate, requireRole } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { paginationSchema, parseWith, uuidSchema } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import { documentStorage } from '../onboarding/document-storage.js';
import {
  allocateIpo,
  approveBrokerApplication,
  approveCompanyApplication,
  approveIpo,
  closeIpo,
  openIpo,
  getBrokerApplicationById,
  getCompanyApplicationById,
  listAllUsers,
  listAuditEvents,
  listBrokerApplications,
  listCompanyApplications,
  listIpo,
  rejectBrokerApplication,
  rejectCompanyApplication,
  rejectIpo,
  requestBrokerAdditionalInfo,
  requestCompanyAdditionalInfo,
  reviewSupportingDocument,
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
  open_immediately: z.boolean().optional(),
});

const openIpoSchema = z.strictObject({
  reason: z.string().max(1000).optional(),
});

const rejectIpoSchema = z.strictObject({
  reason: z.string().min(3).max(1000),
});

const closeIpoSchema = z.strictObject({
  reason: z.string().max(1000).optional(),
});

const listIpoSchema = z.strictObject({
  reason: z.string().max(1000).optional(),
});

const onboardingListQuerySchema = paginationSchema.extend({
  status: z.string().optional(),
});

const approveApplicationSchema = z.strictObject({
  notes: z.string().max(1000).optional(),
});

const rejectApplicationSchema = z.strictObject({
  reason: z.string().min(3).max(1000),
});

const requestInfoSchema = z.strictObject({
  notes: z.string().min(3).max(1000),
});

const reviewDocumentSchema = z.strictObject({
  status: z.enum(['approved', 'rejected']),
  notes: z.string().max(1000).optional(),
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
      open_immediately: body.open_immediately,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // POST /admin/ipos/:id/open
  router.post('/ipos/:id/open', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(openIpoSchema, req.body ?? {});
    const result = await openIpo(deps.db, req.user, id, {
      reason: body.reason,
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

  // POST /admin/ipos/:id/list
  router.post('/ipos/:id/list', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(listIpoSchema, req.body ?? {});
    const result = await listIpo(deps.db, req.user, id, {
      reason: body.reason,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // ── Company Application Management ─────────────────────────────────────────

  router.get('/companies', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const q = parseWith(onboardingListQuerySchema, req.query);
    res.json(await listCompanyApplications(deps.db, q));
  });

  router.get('/companies/:id', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const result = await getCompanyApplicationById(deps.db, id);
    res.json({ data: result });
  });

  router.post('/companies/:id/approve', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(approveApplicationSchema, req.body ?? {});
    const result = await approveCompanyApplication(deps.db, req.user, id, {
      notes: body.notes,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  router.post('/companies/:id/reject', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(rejectApplicationSchema, req.body);
    const result = await rejectCompanyApplication(deps.db, req.user, id, {
      reason: body.reason,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  router.post('/companies/:id/request-info', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(requestInfoSchema, req.body);
    const result = await requestCompanyAdditionalInfo(deps.db, req.user, id, {
      requestNotes: body.notes,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // ── Broker Application Management ──────────────────────────────────────────

  router.get('/brokers', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const q = parseWith(onboardingListQuerySchema, req.query);
    res.json(await listBrokerApplications(deps.db, q));
  });

  router.get('/brokers/:id', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const result = await getBrokerApplicationById(deps.db, id);
    res.json({ data: result });
  });

  router.post('/brokers/:id/approve', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(approveApplicationSchema, req.body ?? {});
    const result = await approveBrokerApplication(deps.db, req.user, id, {
      notes: body.notes,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  router.post('/brokers/:id/reject', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(rejectApplicationSchema, req.body);
    const result = await rejectBrokerApplication(deps.db, req.user, id, {
      reason: body.reason,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  router.post('/brokers/:id/request-info', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(requestInfoSchema, req.body);
    const result = await requestBrokerAdditionalInfo(deps.db, req.user, id, {
      requestNotes: body.notes,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // ── Supporting Documents Review & Access ───────────────────────────────────

  router.patch('/documents/:id/review', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(reviewDocumentSchema, req.body);
    const result = await reviewSupportingDocument(deps.db, req.user, id, {
      status: body.status,
      notes: body.notes,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  router.get('/documents/:id', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const docRes = await deps.db.query(
      'SELECT * FROM supporting_documents WHERE id = $1',
      [id],
    );
    const doc = docRes.rows[0];
    if (!doc) throw Errors.notFound('Document not found');

    const buffer = await documentStorage.readFile(doc.storage_key);
    res.setHeader('Content-Type', doc.mime_type);
    res.setHeader(
      'Content-Disposition',
      `inline; filename="${encodeURIComponent(doc.file_name)}"`,
    );
    res.setHeader('Content-Length', buffer.length);
    res.send(buffer);
  });

  return router;
}

