import { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { parseWith } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import { toUserDto, updateOwnProfile } from './users.service.js';

const phoneSchema = z
  .string()
  .trim()
  .regex(/^\+?[0-9 ()-]{7,20}$/, 'Phone number format is invalid');

// strictObject: unknown fields (e.g. `role`, `balance`) are rejected, not ignored.
const updateProfileSchema = z
  .strictObject({
    full_name: z.string().trim().min(1).max(120).optional(),
    phone: phoneSchema.nullable().optional(),
  })
  .refine((v) => v.full_name !== undefined || v.phone !== undefined, {
    message: 'At least one field is required',
  });

export function usersRouter(deps: AppDeps): Router {
  const router = Router();
  const authenticate = createAuthenticate(deps);

  router.get('/me', authenticate, (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    res.json({ data: toUserDto(req.user) });
  });

  router.patch('/me', authenticate, async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const patch = parseWith(updateProfileSchema, req.body);
    const updated = await updateOwnProfile(deps.db, req.user, patch);
    res.json({ data: toUserDto(updated) });
  });

  return router;
}
