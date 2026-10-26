import { randomUUID } from 'node:crypto';
import cors from 'cors';
import express from 'express';
import type { Express } from 'express';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';
import { createErrorHandler, notFoundHandler } from './http/error-handler.js';
import type { AppDeps } from './http/types.js';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { adminRouter } from './modules/admin/admin.routes.js';
import { authRouter } from './modules/auth/auth.routes.js';
import { aiRouter } from './modules/ai/ai.routes.js';
import { brokersRouter } from './modules/brokers/brokers.routes.js';
import { healthRouter } from './modules/health/health.routes.js';
import { iposRouter } from './modules/ipos/ipos.routes.js';
import { onboardingRouter } from './modules/onboarding/onboarding.routes.js';
import { portfolioRouter } from './modules/portfolio/portfolio.routes.js';
import { subscriptionsRouter } from './modules/subscriptions/subscriptions.routes.js';
import { tradingRouter } from './modules/trading/trading.routes.js';
import { usersRouter } from './modules/users/users.routes.js';
import { devRouter, walletsRouter } from './modules/wallet/wallet.routes.js';

const REQUEST_ID_RE = /^[A-Za-z0-9._-]{8,64}$/;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const portalsDir = path.resolve(__dirname, '../../portals');

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

  app.use(helmet({
    contentSecurityPolicy: false, // Allow portals to load Google Fonts, icons, and inline styles
  }));
  app.use(
    cors({
      origin: (origin, cb) => {
        const isLocalDevelopmentOrigin =
          env.NODE_ENV !== 'production' &&
          !!origin &&
          /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
        cb(null, !origin || env.CORS_ORIGINS.includes(origin) || isLocalDevelopmentOrigin);
      },
      methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Authorization', 'Content-Type', 'Idempotency-Key', 'X-Request-Id'],
      exposedHeaders: ['X-Request-Id', 'Idempotent-Replay'],
      maxAge: 600,
    }),
  );
  app.use(express.json({ limit: '15mb' }));

  // Static Portals for Option C Web Onboarding
  app.use('/portal/company', express.static(path.join(portalsDir, 'company')));
  app.use('/portal/broker', express.static(path.join(portalsDir, 'broker')));

  app.use('/health', healthRouter(deps.db));
  app.use('/auth', authRouter(deps));
  app.use('/ai', aiRouter(deps));
  app.use('/users', usersRouter(deps));
  app.use('/ipos', iposRouter(deps));
  app.use('/subscriptions', subscriptionsRouter(deps));
  app.use('/portfolio', portfolioRouter(deps));
  app.use('/wallets', walletsRouter(deps));
  app.use('/admin', adminRouter(deps));
  app.use('/brokers', brokersRouter(deps));
  app.use('/trading', tradingRouter(deps));
  app.use('/onboarding', onboardingRouter(deps));
  if (env.ENABLE_TEST_FUNDS && env.NODE_ENV !== 'production') {
    app.use('/dev', devRouter(deps));
  }

  app.use(notFoundHandler);
  app.use(createErrorHandler(logger));
  return app;
}
