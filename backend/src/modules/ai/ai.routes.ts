import { Router } from 'express';
import rateLimit, { ipKeyGenerator } from 'express-rate-limit';
import { z } from 'zod';
import { createAuthenticate } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { parseWith, uuidSchema } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import { chat } from './ai.service.js';

const schema = z.strictObject({
  message: z.string().trim().min(1).max(1000),
  language: z.enum(['en', 'am']).default('en'),
  ipo_id: uuidSchema.optional(),
  history: z.array(z.strictObject({
    role: z.enum(['user', 'assistant']),
    content: z.string().max(1000),
  })).max(6).default([]),
});

export function aiRouter(deps: AppDeps): Router {
  const router = Router();
  router.use(createAuthenticate(deps));
  router.use(rateLimit({
    windowMs: 60_000,
    limit: deps.env.AI_RATE_LIMIT_MAX,
    keyGenerator: (req) => req.user?.id ?? ipKeyGenerator(req.ip ?? 'unknown'),
    handler: (_req, _res, next) => next(Errors.rateLimited()),
    standardHeaders: false,
    legacyHeaders: false,
  }));
  router.post('/chat', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const input = parseWith(schema, req.body);
    const result = await chat(deps, req.user, input, req.requestId);
    const { _outcome, _latency_ms, ...response } = result;
    deps.logger.info({
      request_id: req.requestId,
      user_id: req.user.id,
      role: req.user.role,
      language: response.language,
      grounded: response.grounded,
      provider: response.simulated ? 'mock' : deps.env.AI_PROVIDER,
      latency_ms: _latency_ms,
      outcome: _outcome,
      input_length: input.message.length,
    }, 'AI request');
    res.json({ data: response });
  });
  return router;
}
