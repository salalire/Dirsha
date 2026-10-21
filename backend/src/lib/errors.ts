/**
 * Application errors with stable, machine-readable codes.
 * Clients (mobile/admin) switch on `code`, never on `message`.
 */
export type ErrorCode =
  | 'VALIDATION_ERROR'
  | 'UNAUTHENTICATED'
  | 'INVALID_CREDENTIALS'
  | 'FORBIDDEN'
  | 'ACCOUNT_SUSPENDED'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'EMAIL_ALREADY_REGISTERED'
  | 'RATE_LIMITED'
  | 'INSUFFICIENT_FUNDS'
  | 'IPO_NOT_OPEN'
  | 'IDEMPOTENCY_KEY_REUSED'
  | 'INTERNAL_ERROR';

export class AppError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: ErrorCode,
    message: string,
    public readonly details?: unknown,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export const Errors = {
  validation: (details: unknown, message = 'Request validation failed') =>
    new AppError(400, 'VALIDATION_ERROR', message, details),
  unauthenticated: (message = 'Authentication is required') =>
    new AppError(401, 'UNAUTHENTICATED', message),
  invalidCredentials: () =>
    new AppError(401, 'INVALID_CREDENTIALS', 'Email or password is incorrect'),
  forbidden: (message = 'You do not have permission to perform this action') =>
    new AppError(403, 'FORBIDDEN', message),
  accountSuspended: () =>
    new AppError(403, 'ACCOUNT_SUSPENDED', 'This account is suspended'),
  notFound: (message = 'Resource not found') => new AppError(404, 'NOT_FOUND', message),
  emailTaken: () =>
    new AppError(409, 'EMAIL_ALREADY_REGISTERED', 'An account with this email already exists'),
  rateLimited: () =>
    new AppError(429, 'RATE_LIMITED', 'Too many attempts. Please try again later'),
  insufficientFunds: () =>
    new AppError(422, 'INSUFFICIENT_FUNDS', 'Available balance is not enough for this operation'),
  idempotencyKeyReused: () =>
    new AppError(
      409,
      'IDEMPOTENCY_KEY_REUSED',
      'This Idempotency-Key was already used with a different request',
    ),
};
