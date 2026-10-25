import { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { paginationSchema, parseWith, uuidSchema } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import { IPO_STATUSES, listIpos } from '../ipos/ipos.service.js';
import {
  getAuthorizedClientDetail,
  getBrokerDashboard,
  getBrokerProfile,
  listBrokerClients,
  listInvestorBrokerRelationships,
  requestClientRelationship,
  respondToRelationship,
} from './brokers.service.js';

const requestClientSchema = z.strictObject({
  investor_email: z.string().trim().email(),
  relationship_type: z.enum(['advisory', 'discretionary', 'execution_only']).default('advisory'),
  notes: z.string().max(1000).optional(),
});

const listClientsQuerySchema = z.strictObject({
  status: z.enum(['pending', 'active', 'rejected', 'revoked']).optional(),
});

const respondRelationshipSchema = z.strictObject({
  action: z.enum(['accept', 'reject', 'revoke']),
});

export function brokersRouter(deps: AppDeps): Router {
  const router = Router();
  router.use(createAuthenticate(deps));

  // GET /brokers/me: Profile of authenticated broker
  router.get('/me', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const profile = await getBrokerProfile(deps.db, req.user);
    res.json(profile);
  });

  // GET /brokers/dashboard: Broker dashboard metrics & profile
  router.get('/dashboard', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const dashboard = await getBrokerDashboard(deps.db, req.user);
    res.json(dashboard);
  });

  // GET /brokers/ipos: Offerings accessible to broker
  router.get('/ipos', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const query = parseWith(
      paginationSchema.extend({ status: z.enum(IPO_STATUSES).optional() }),
      req.query,
    );
    const offerings = await listIpos(deps.db, req.user, query);
    res.json(offerings);
  });

  // POST /brokers/clients/request: Initiate authorized client relationship
  router.post('/clients/request', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const body = parseWith(requestClientSchema, req.body);
    const result = await requestClientRelationship(deps.db, req.user, body, {
      requestId: req.requestId,
    });
    res.status(201).json(result);
  });

  // GET /brokers/clients: List broker's client relationships
  router.get('/clients', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const query = parseWith(listClientsQuerySchema, req.query);
    const result = await listBrokerClients(deps.db, req.user, query.status);
    res.json(result);
  });

  // GET /brokers/clients/:clientId: Detail, wallet, and share holdings for authorized client
  router.get('/clients/:clientId', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const clientId = parseWith(uuidSchema, req.params.clientId);
    const result = await getAuthorizedClientDetail(deps.db, req.user, clientId);
    res.json(result);
  });

  // GET /brokers/relationships/my: Investor view of all broker relationship requests
  router.get('/relationships/my', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const result = await listInvestorBrokerRelationships(deps.db, req.user);
    res.json(result);
  });

  // POST /brokers/relationships/:id/respond: Investor accepts, rejects, or revokes relationship
  router.post('/relationships/:id/respond', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const relId = parseWith(uuidSchema, req.params.id);
    const body = parseWith(respondRelationshipSchema, req.body);
    const result = await respondToRelationship(deps.db, req.user, relId, body.action, {
      requestId: req.requestId,
    });
    res.json(result);
  });

  return router;
}
