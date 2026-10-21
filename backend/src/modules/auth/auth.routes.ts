import { Router } from 'express';
import { rateLimit } from 'express-rate-limit';
import { z } from 'zod';
import type { AppDeps } from '../../http/types.js';
import { parseWith } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import { createAuthService } from './auth.service.js';

const MAX_PASSWORD_BYTES = 72; // bcrypt ignores everything after 72 bytes

const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .refine((p) => Buffer.byteLength(p, 'utf8') <= MAX_PASSWORD_BYTES, {
    message: `Password must be at most ${MAX_PASSWORD_BYTES} bytes`,
  });

const emailSchema = z.string().trim().max(254).pipe(z.email());

// Public self-registration can never create an admin. Admin accounts are provisioned
// out-of-band (see backend/README.md). `strictObject` rejects unknown fields.
const registerSchema = z.strictObject({
  email: emailSchema,
  password: passwordSchema,
  full_name: z.string().trim().min(1).max(120),
  phone: z
    .string()
    .trim()
    .regex(/^\+?[0-9 ()-]{7,20}$/, 'Phone number format is invalid')
    .optional(),
  role: z.enum(['investor', 'company_rep', 'broker']),
});

const loginSchema = z.strictObject({
  email: emailSchema,
  password: z.string().min(1).max(1024),
});

export function authRouter(deps: AppDeps): Router {
  const router = Router();
  const service = createAuthService(deps);

  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: deps.env.AUTH_RATE_LIMIT_MAX,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    handler: (_req, _res, next) => next(Errors.rateLimited()),
  });

  router.post('/register', limiter, async (req, res) => {
    const body = parseWith(registerSchema, req.body);
    const user = await service.register(
      {
        email: body.email,
        password: body.password,
        fullName: body.full_name,
        phone: body.phone,
        role: body.role,
      },
      req.requestId,
    );
    res.status(201).json({ data: user });
  });

  router.post('/login', limiter, async (req, res) => {
    const body = parseWith(loginSchema, req.body);
    const result = await service.login(body.email, body.password, req.requestId);
    res.json({ data: result });
  });

  return router;
}
