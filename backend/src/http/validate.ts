import { z } from 'zod';
import { Errors } from '../lib/errors.js';

/**
 * Validate untrusted input. Error details name the failing field and rule but
 * never echo the submitted value (it may be a password or other sensitive data).
 */
export function parseWith<T>(schema: z.ZodType<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw Errors.validation(
      result.error.issues.map((i) => ({ field: i.path.join('.') || '(body)', message: i.message })),
    );
  }
  return result.data;
}

export const uuidSchema = z.uuid();

export const idempotencyKeySchema = z
  .string()
  .min(8, 'Idempotency-Key must be at least 8 characters')
  .max(128)
  .regex(/^[A-Za-z0-9._:-]+$/, 'Idempotency-Key contains invalid characters');

/** Standard pagination query parameters. */
export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).max(100_000).default(1),
  page_size: z.coerce.number().int().min(1).max(100).default(20),
});

export interface Pagination {
  page: number;
  page_size: number;
  total: number;
}
