import { z } from 'zod';

/**
 * Environment validation. The server refuses to start with a missing or unsafe
 * configuration. Values are never logged.
 */
const boolFromString = z
  .enum(['true', 'false'])
  .default('false')
  .transform((v) => v === 'true');

const envSchema = z
  .object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    PORT: z.coerce.number().int().min(1).max(65535).default(3000),
    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
    DATABASE_URL: z
      .string()
      .min(1, 'DATABASE_URL is required')
      .refine((v) => /^postgres(ql)?:\/\//.test(v), 'DATABASE_URL must be a postgres:// URL'),
    JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET must be at least 32 characters'),
    JWT_ACCESS_TTL_SECONDS: z.coerce.number().int().min(60).max(86_400).default(900),
    BCRYPT_COST: z.coerce.number().int().min(4).max(15).default(12),
    CORS_ORIGINS: z
      .string()
      .default('')
      .transform((v) =>
        v
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean),
      ),
    ENABLE_TEST_FUNDS: boolFromString,
    // Max sign-in/registration attempts per client IP per 15 minutes (FR-AUTH-08).
    AUTH_RATE_LIMIT_MAX: z.coerce.number().int().min(1).max(10_000).default(20),
  })
  .superRefine((env, ctx) => {
    if (env.NODE_ENV === 'production' && env.ENABLE_TEST_FUNDS) {
      ctx.addIssue({
        code: 'custom',
        path: ['ENABLE_TEST_FUNDS'],
        message: 'ENABLE_TEST_FUNDS must not be "true" when NODE_ENV=production',
      });
    }
    if (env.NODE_ENV === 'production' && /CHANGE_ME/i.test(env.JWT_ACCESS_SECRET)) {
      ctx.addIssue({
        code: 'custom',
        path: ['JWT_ACCESS_SECRET'],
        message: 'JWT_ACCESS_SECRET still contains the placeholder value',
      });
    }
  });

export type Env = z.infer<typeof envSchema>;

export class EnvValidationError extends Error {
  constructor(public readonly issues: string[]) {
    super(`Invalid environment configuration:\n - ${issues.join('\n - ')}`);
    this.name = 'EnvValidationError';
  }
}

/** Parse and validate a raw environment object. Error messages never echo values. */
export function parseEnv(raw: NodeJS.ProcessEnv): Env {
  const result = envSchema.safeParse(raw);
  if (!result.success) {
    throw new EnvValidationError(
      result.error.issues.map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`),
    );
  }
  return result.data;
}
