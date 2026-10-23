import express, { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { parseWith, uuidSchema } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import {
  deleteCompanyDocument,
  getCompanyApplication,
  getCompanyDocumentFile,
  saveCompanyDraft,
  submitCompanyApplication,
  uploadCompanyDocument,
} from './company-onboarding.service.js';
import {
  deleteBrokerDocument,
  getBrokerApplication,
  getBrokerDocumentFile,
  saveBrokerDraft,
  submitBrokerApplication,
  uploadBrokerDocument,
} from './broker-onboarding.service.js';

const companyDraftSchema = z.strictObject({
  legal_name: z.string().trim().min(1).max(255),
  trade_name: z.string().trim().max(255).optional(),
  registration_number: z.string().trim().min(1).max(100),
  legal_entity_type: z
    .enum(['plc', 'share_company', 'sole_proprietorship', 'partnership', 'corporation', 'other'])
    .optional(),
  country_of_incorporation: z.string().trim().max(100).optional(),
  incorporation_date: z.string().trim().optional(),
  business_address: z.string().trim().max(500).optional(),
  operating_address: z.string().trim().max(500).optional(),
  business_email: z.string().trim().max(254).pipe(z.email()).optional(),
  business_phone: z.string().trim().max(50).optional(),
  website: z.string().trim().max(255).optional(),
  industry_sector: z.string().trim().max(100).optional(),
  description: z.string().trim().max(2000).optional(),
  tin: z.string().trim().max(50).optional(),
  vat_number: z.string().trim().max(50).optional(),
  representative_name: z.string().trim().max(120).optional(),
  representative_email: z.string().trim().max(254).pipe(z.email()).optional(),
  representative_phone: z.string().trim().max(50).optional(),
  representative_title: z.string().trim().max(100).optional(),
  representative_role_description: z.string().trim().max(500).optional(),
  authority_declaration: z.boolean().optional(),
});

const brokerDraftSchema = z.strictObject({
  broker_type: z.enum(['individual', 'firm']).optional(),
  legal_name: z.string().trim().min(1).max(255),
  trade_name: z.string().trim().max(255).optional(),
  registration_number: z.string().trim().max(100).optional(),
  tin: z.string().trim().max(50).optional(),
  business_address: z.string().trim().max(500).optional(),
  city: z.string().trim().max(100).optional(),
  country: z.string().trim().max(100).optional(),
  business_email: z.string().trim().max(254).pipe(z.email()).optional(),
  business_phone: z.string().trim().max(50).optional(),
  website: z.string().trim().max(255).optional(),
  license_number: z.string().trim().min(1).max(100),
  license_category: z.string().trim().min(1).max(100),
  licensing_authority: z.string().trim().max(255).optional(),
  license_issued_date: z.string().trim().optional(),
  license_expiry_date: z.string().trim().min(4).max(50),
  representative_name: z.string().trim().max(120).optional(),
  representative_email: z.string().trim().max(254).pipe(z.email()).optional(),
  representative_phone: z.string().trim().max(50).optional(),
  representative_title: z.string().trim().max(100).optional(),
  authority_declaration: z.boolean().optional(),
});

const documentUploadSchema = z.strictObject({
  document_type: z.string().trim().min(1).max(100),
  file_name: z.string().trim().min(1).max(255),
  mime_type: z.string().trim().min(1).max(100),
  content: z.string().min(1, 'Document content (base64) is required'),
});

export function onboardingRouter(deps: AppDeps): Router {
  const router = Router();
  const auth = createAuthenticate(deps);

  // ── Company Representative Onboarding ───────────────────────────────────────

  router.get('/company', auth, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const app = await getCompanyApplication(deps.db, req.user);
    res.json({ data: app });
  });

  router.post('/company/draft', auth, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const body = parseWith(companyDraftSchema, req.body);
    const result = await saveCompanyDraft(deps.db, req.user, body);
    res.status(200).json({ data: result });
  });

  router.post('/company/submit', auth, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const result = await submitCompanyApplication(deps.db, req.user);
    res.status(200).json({ data: result });
  });

  router.post(
    '/company/documents',
    auth,
    express.json({ limit: '15mb' }),
    async (req, res) => {
      if (!req.user) throw Errors.unauthenticated();
      const body = parseWith(documentUploadSchema, req.body);
      const result = await uploadCompanyDocument(deps.db, req.user, body);
      res.status(201).json({ data: result });
    },
  );

  router.delete('/company/documents/:id', auth, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const docId = parseWith(uuidSchema, req.params.id);
    const result = await deleteCompanyDocument(deps.db, req.user, docId);
    res.json({ data: result });
  });

  // ── Broker Onboarding ──────────────────────────────────────────────────────

  router.get('/broker', auth, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const app = await getBrokerApplication(deps.db, req.user);
    res.json({ data: app });
  });

  router.post('/broker/draft', auth, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const body = parseWith(brokerDraftSchema, req.body);
    const result = await saveBrokerDraft(deps.db, req.user, body);
    res.status(200).json({ data: result });
  });

  router.post('/broker/submit', auth, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const result = await submitBrokerApplication(deps.db, req.user);
    res.status(200).json({ data: result });
  });

  router.post(
    '/broker/documents',
    auth,
    express.json({ limit: '15mb' }),
    async (req, res) => {
      if (!req.user) throw Errors.unauthenticated();
      const body = parseWith(documentUploadSchema, req.body);
      const result = await uploadBrokerDocument(deps.db, req.user, body);
      res.status(201).json({ data: result });
    },
  );

  router.delete('/broker/documents/:id', auth, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const docId = parseWith(uuidSchema, req.params.id);
    const result = await deleteBrokerDocument(deps.db, req.user, docId);
    res.json({ data: result });
  });

  // ── Supporting Documents Access ───────────────────────────────────────────

  router.get('/documents/:id', auth, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const docId = parseWith(uuidSchema, req.params.id);

    // Check entity type
    const docRes = await deps.db.query(
      'SELECT * FROM supporting_documents WHERE id = $1',
      [docId],
    );
    const doc = docRes.rows[0];
    if (!doc) throw Errors.notFound('Document not found');

    if (doc.owner_user_id !== req.user.id && req.user.role !== 'admin') {
      throw Errors.forbidden('You do not have permission to view this document');
    }

    if (req.query.meta === 'true') {
      return res.json({ data: doc });
    }

    const file = doc.entity_type === 'company'
      ? await getCompanyDocumentFile(deps.db, req.user, docId)
      : await getBrokerDocumentFile(deps.db, req.user, docId);

    res.setHeader('Content-Type', file.mimeType);
    res.setHeader(
      'Content-Disposition',
      `inline; filename="${encodeURIComponent(file.fileName)}"`,
    );
    res.setHeader('Content-Length', file.buffer.length);
    res.send(file.buffer);
  });

  return router;
}
