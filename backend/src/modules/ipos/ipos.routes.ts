import { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { paginationSchema, parseWith, uuidSchema } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import {
  createIpoDraft,
  deleteIpoDocument,
  getIpo,
  getIpoDocumentFile,
  getIpoHistory,
  IPO_STATUSES,
  listCompanyOfferings,
  listIpoDocuments,
  listIpos,
  submitIpo,
  updateIpoDraft,
  uploadIpoDocument,
} from './ipos.service.js';

const listQuerySchema = paginationSchema.extend({
  status: z.enum(IPO_STATUSES).optional(),
});

const createIpoSchema = z.strictObject({
  title: z.string().trim().min(3).max(200),
  symbol: z
    .string()
    .trim()
    .min(2)
    .max(10)
    .regex(/^[A-Za-z0-9]+$/, 'Symbol must be alphanumeric'),
  description: z.string().max(4000).optional().nullable(),
  price_per_share_minor: z.number().int().positive(),
  total_shares: z.number().int().positive(),
  min_shares_per_subscription: z.number().int().positive().default(1),
  max_shares_per_subscription: z.number().int().positive().optional().nullable(),
  opens_at: z.string().datetime(),
  closes_at: z.string().datetime(),
  company_id: uuidSchema.optional(),
});

const updateIpoSchema = z.strictObject({
  title: z.string().trim().min(3).max(200).optional(),
  symbol: z
    .string()
    .trim()
    .min(2)
    .max(10)
    .regex(/^[A-Za-z0-9]+$/, 'Symbol must be alphanumeric')
    .optional(),
  description: z.string().max(4000).optional().nullable(),
  price_per_share_minor: z.number().int().positive().optional(),
  total_shares: z.number().int().positive().optional(),
  min_shares_per_subscription: z.number().int().positive().optional(),
  max_shares_per_subscription: z.number().int().positive().optional().nullable(),
  opens_at: z.string().datetime().optional(),
  closes_at: z.string().datetime().optional(),
});

const submitIpoSchema = z.strictObject({
  notes: z.string().max(1000).optional(),
});

const uploadIpoDocSchema = z.strictObject({
  document_type: z.enum([
    'prospectus',
    'financial_statement',
    'ecma_approval',
    'board_resolution',
    'valuation_report',
    'articles_of_association',
    'other',
  ]),
  file_name: z.string().min(1).max(255),
  mime_type: z.string(),
  content: z.string().min(1),
});

export function iposRouter(deps: AppDeps): Router {
  const router = Router();
  router.use(createAuthenticate(deps));

  // GET /ipos: list public or visible IPOs
  router.get('/', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const q = parseWith(listQuerySchema, req.query);
    res.json(await listIpos(deps.db, req.user, q));
  });

  // GET /ipos/my-offerings: list caller's company offerings
  router.get('/my-offerings', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    res.json(await listCompanyOfferings(deps.db, req.user));
  });

  // POST /ipos: create new draft offering (company_rep / admin)
  router.post('/', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const body = parseWith(createIpoSchema, req.body);
    const result = await createIpoDraft(deps.db, req.user, body, {
      requestId: req.requestId,
    });
    res.status(201).json({ data: result });
  });

  // GET /ipos/:id: get single IPO details
  router.get('/:id', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const ipo = await getIpo(deps.db, req.user, id);
    if (!ipo) throw Errors.notFound('IPO not found');
    res.json({ data: ipo });
  });

  // PUT /ipos/:id: update draft offering
  router.put('/:id', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(updateIpoSchema, req.body);
    const result = await updateIpoDraft(deps.db, req.user, id, body, {
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // POST /ipos/:id/submit: submit draft offering for administrative review
  router.post('/:id/submit', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(submitIpoSchema, req.body ?? {});
    const result = await submitIpo(deps.db, req.user, id, {
      notes: body.notes,
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // POST /ipos/:id/documents: upload offering document
  router.post('/:id/documents', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const body = parseWith(uploadIpoDocSchema, req.body);
    const result = await uploadIpoDocument(deps.db, req.user, id, body, {
      requestId: req.requestId,
    });
    res.status(201).json({ data: result });
  });

  // GET /ipos/:id/documents: list offering documents
  router.get('/:id/documents', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const result = await listIpoDocuments(deps.db, req.user, id);
    res.json({ data: result });
  });

  // GET /ipos/:id/documents/:docId/file: download offering document
  router.get('/:id/documents/:docId/file', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const docId = parseWith(uuidSchema, req.params.docId);
    const { buffer, mimeType, fileName } = await getIpoDocumentFile(
      deps.db,
      req.user,
      id,
      docId,
    );
    res.setHeader('Content-Type', mimeType);
    res.setHeader('Content-Disposition', `inline; filename="${fileName}"`);
    res.send(buffer);
  });

  // DELETE /ipos/:id/documents/:docId: delete offering document (draft only)
  router.delete('/:id/documents/:docId', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const docId = parseWith(uuidSchema, req.params.docId);
    const result = await deleteIpoDocument(deps.db, req.user, id, docId, {
      requestId: req.requestId,
    });
    res.json({ data: result });
  });

  // GET /ipos/:id/history: view status history
  router.get('/:id/history', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const id = parseWith(uuidSchema, req.params.id);
    const result = await getIpoHistory(deps.db, req.user, id);
    res.json({ data: result });
  });

  return router;
}
