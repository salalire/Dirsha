import { pino } from 'pino';
import type { Logger } from 'pino';

/**
 * Paths that must never appear in logs (FR-ADM-05, NFR-SEC-09).
 * pino replaces these with "[REDACTED]".
 */
export const REDACT_PATHS = [
  'req.headers.authorization',
  'req.headers.cookie',
  'req.headers["idempotency-key"]',
  'res.headers["set-cookie"]',
  '*.password',
  '*.passwordHash',
  '*.password_hash',
  '*.token',
  '*.accessToken',
  '*.refreshToken',
  '*.secret',
  'password',
  'passwordHash',
  'token',
  'accessToken',
  'refreshToken',
];

export function createLogger(level: string): Logger {
  return pino({
    level,
    redact: { paths: REDACT_PATHS, censor: '[REDACTED]' },
    base: { service: 'dirsha-backend' },
  });
}
