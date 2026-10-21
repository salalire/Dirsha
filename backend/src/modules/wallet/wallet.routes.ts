import { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate, requireRole } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { paginationSchema, parseWith } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import {
  creditOwnTestFunds,
  getOwnWallet,
  listOwnTransactions,
  MAX_TEST_FUND_MINOR,
} from './wallet.service.js';

const idempotencyKeySchema = z
  .string()
  .min(8, 'Idempotency-Key must be at least 8 characters')
  .max(128)
  .regex(/^[A-Za-z0-9._:-]+$/, 'Idempotency-Key contains invalid characters');

const testFundsSchema = z.strictObject({
  amount_minor: z.number().int().min(1).max(MAX_TEST_FUND_MINOR),
});

/** GET /wallets/me and /wallets/me/transactions: investors only, own data only. */
export function walletsRouter(deps: AppDeps): Router {
  const router = Router();
  router.use(createAuthenticate(deps), requireRole('investor'));

  router.get('/me', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    res.json({ data: await getOwnWallet(deps.db, req.user) });
  });

  router.get('/me/transactions', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const q = parseWith(paginationSchema, req.query);
    res.json(await listOwnTransactions(deps.db, req.user, q));
  });

  return router;
}

/**
 * POST /dev/test-funds. Only mounted when ENABLE_TEST_FUNDS=true (never in production).
 * See creditOwnTestFunds for the safeguards.
 */
export function devRouter(deps: AppDeps): Router {
  const router = Router();
  router.use(createAuthenticate(deps), requireRole('investor'));

  router.post('/test-funds', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    // Defence in depth: env validation already forbids this combination.
    if (!deps.env.ENABLE_TEST_FUNDS || deps.env.NODE_ENV === 'production') {
      throw Errors.notFound();
    }
    const key = parseWith(idempotencyKeySchema, req.header('idempotency-key'));
    const body = parseWith(testFundsSchema, req.body);
    const result = await creditOwnTestFunds(deps.db, req.user, {
      amountMinor: body.amount_minor,
      idempotencyKey: key,
      requestId: req.requestId,
    });
    res
      .status(result.replayed ? 200 : 201)
      .set('Idempotent-Replay', String(result.replayed))
      .json({ data: { transaction: result.entry, wallet: result.wallet } });
  });

  return router;
}
