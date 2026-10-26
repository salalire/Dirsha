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
    AI_PROVIDER: z.enum(['mock', 'bedrock', 'gemini']).default('mock'),
    AI_MODEL_ID: z.string().min(1).optional(),
    GEMINI_API_KEY: z.string().min(1).optional(),
    GEMINI_MODEL_ID: z.string().min(1).optional(),
    AWS_REGION: z.string().min(1).optional(),
    AI_TIMEOUT_MS: z.coerce.number().int().min(1000).max(60_000).default(12_000),
    AI_RATE_LIMIT_MAX: z.coerce.number().int().min(1).max(10_000).default(20),
    AI_ALLOW_MOCK_FALLBACK: boolFromString,
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
    if (env.AI_PROVIDER === 'bedrock' && !env.AI_MODEL_ID) {
      ctx.addIssue({
        code: 'custom',
        path: ['AI_MODEL_ID'],
        message: 'AI_MODEL_ID is required when AI_PROVIDER=bedrock',
      });
    }
    if (env.AI_PROVIDER === 'bedrock' && !env.AWS_REGION) {
      ctx.addIssue({
        code: 'custom',
        path: ['AWS_REGION'],
        message: 'AWS_REGION is required when AI_PROVIDER=bedrock',
      });
    }
    if (env.AI_PROVIDER === 'gemini' && !env.GEMINI_API_KEY) {
      ctx.addIssue({
        code: 'custom',
        path: ['GEMINI_API_KEY'],
        message: 'GEMINI_API_KEY is required when AI_PROVIDER=gemini',
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
