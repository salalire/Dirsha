import type { ErrorRequestHandler, RequestHandler } from 'express';
import type { Logger } from 'pino';
import { AppError, Errors } from '../lib/errors.js';

/** Error envelope returned by every failing request (documented in docs/API_SPECIFICATION.md). */
export interface ErrorBody {
  error: {
    code: string;
    message: string;
    details?: unknown;
    request_id: string;
  };
}

export const notFoundHandler: RequestHandler = (_req, _res, next) => {
  next(Errors.notFound('Route not found'));
};

interface BodyParserError {
  type?: string;
  status?: number;
}

export function createErrorHandler(logger: Logger): ErrorRequestHandler {
  return (err: unknown, req, res, next) => {
    if (res.headersSent) {
      next(err);
      return;
    }

    let appError: AppError;
    const bp = err as BodyParserError;
    if (err instanceof AppError) {
      appError = err;
    } else if (bp?.type === 'entity.parse.failed') {
      appError = new AppError(400, 'VALIDATION_ERROR', 'Request body is not valid JSON');
    } else if (bp?.type === 'entity.too.large') {
      appError = new AppError(413, 'VALIDATION_ERROR', 'Request body is too large');
    } else {
      // Unknown failure: log the details server-side, return nothing sensitive.
      logger.error({ err, request_id: req.requestId }, 'unhandled error');
      appError = new AppError(500, 'INTERNAL_ERROR', 'An unexpected error occurred');
    }

    const body: ErrorBody = {
      error: {
        code: appError.code,
        message: appError.message,
        ...(appError.details !== undefined ? { details: appError.details } : {}),
        request_id: req.requestId,
      },
    };
    res.status(appError.status).json(body);
  };
}
