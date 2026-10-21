import { randomUUID } from 'node:crypto';
import cors from 'cors';
import express from 'express';
import type { Express } from 'express';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';
import { createErrorHandler, notFoundHandler } from './http/error-handler.js';
import type { AppDeps } from './http/types.js';
import { authRouter } from './modules/auth/auth.routes.js';
import { healthRouter } from './modules/health/health.routes.js';
import { iposRouter } from './modules/ipos/ipos.routes.js';
import { usersRouter } from './modules/users/users.routes.js';
import { devRouter, walletsRouter } from './modules/wallet/wallet.routes.js';

const REQUEST_ID_RE = /^[A-Za-z0-9._-]{8,64}$/;

/**
 * Builds the Express app from explicit dependencies (config, database, logger) so the
 * same code runs in production and in tests against a throw-away database.
 */
export function createApp(deps: AppDeps): Express {
  const { env, logger } = deps;
  const app = express();

  app.disable('x-powered-by');

  // Correlation id: accept a well-formed client-supplied one, otherwise generate (NFR-REL-01).
  app.use((req, res, next) => {
    const incoming = req.header('x-request-id');
    req.requestId = incoming && REQUEST_ID_RE.test(incoming) ? incoming : randomUUID();
    res.setHeader('X-Request-Id', req.requestId);
    next();
  });

  app.use(
    pinoHttp({
      logger,
      genReqId: (req) => (req as express.Request).requestId,
      // Log method, path (no query string) and status only: never bodies or auth headers.
      serializers: {
        req: (req: { id: string; method: string; url: string }) => ({
          id: req.id,
          method: req.method,
          url: req.url.split('?')[0],
        }),
        res: (res: { statusCode: number }) => ({ statusCode: res.statusCode }),
      },
      autoLogging: env.NODE_ENV !== 'test',
    }),
  );

  app.use(helmet());
  app.use(
    cors({
      origin: (origin, cb) => cb(null, !origin || env.CORS_ORIGINS.includes(origin)),
      methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Authorization', 'Content-Type', 'Idempotency-Key', 'X-Request-Id'],
      exposedHeaders: ['X-Request-Id', 'Idempotent-Replay'],
      maxAge: 600,
    }),
  );
  app.use(express.json({ limit: '100kb' }));

  app.use('/health', healthRouter(deps.db));
  app.use('/auth', authRouter(deps));
  app.use('/users', usersRouter(deps));
  app.use('/ipos', iposRouter(deps));
  app.use('/wallets', walletsRouter(deps));
  if (env.ENABLE_TEST_FUNDS && env.NODE_ENV !== 'production') {
    app.use('/dev', devRouter(deps));
  }

  app.use(notFoundHandler);
  app.use(createErrorHandler(logger));
  return app;
}
