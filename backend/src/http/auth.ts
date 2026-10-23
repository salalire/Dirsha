import type { RequestHandler } from 'express';
import jwt from 'jsonwebtoken';
import type { Env } from '../config/env.js';
import { Errors } from '../lib/errors.js';
import type { AppDeps, AuthUser, Role } from './types.js';

export const TOKEN_ISSUER = 'dirsha-backend';
export const TOKEN_AUDIENCE = 'dirsha-api';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Access token carries ONLY the user id (`sub`). The role and account status are
 * re-read from the database on every request, so a token can never assert its own
 * privileges and a suspension takes effect immediately (FR-AUTH-04, FR-AUTH-06).
 */
export function signAccessToken(env: Env, userId: string): { token: string; expiresIn: number } {
  const token = jwt.sign({}, env.JWT_ACCESS_SECRET, {
    algorithm: 'HS256',
    subject: userId,
    issuer: TOKEN_ISSUER,
    audience: TOKEN_AUDIENCE,
    expiresIn: env.JWT_ACCESS_TTL_SECONDS,
  });
  return { token, expiresIn: env.JWT_ACCESS_TTL_SECONDS };
}

interface UserRow {
  id: string;
  email: string;
  full_name: string;
  phone: string | null;
  role: Role;
  account_status: AuthUser['accountStatus'];
  verification_status: AuthUser['verificationStatus'];
  created_at: Date;
}

/** Authenticate the request: valid, unexpired token for an existing, active account. */
export function createAuthenticate({ env, db }: Pick<AppDeps, 'env' | 'db'>): RequestHandler {
  return async (req, _res, next) => {
    const header = req.header('authorization');
    const match = header ? /^Bearer\s+(\S+)$/i.exec(header) : null;
    const rawToken = match?.[1] ?? (typeof req.query.token === 'string' ? req.query.token : undefined);
    if (!rawToken) {
      throw Errors.unauthenticated();
    }

    let subject: string | undefined;
    try {
      const payload = jwt.verify(rawToken, env.JWT_ACCESS_SECRET, {
        algorithms: ['HS256'],
        issuer: TOKEN_ISSUER,
        audience: TOKEN_AUDIENCE,
      });
      subject = typeof payload === 'object' ? payload.sub : undefined;
    } catch {
      throw Errors.unauthenticated('Access token is invalid or expired');
    }
    if (!subject || !UUID_RE.test(subject)) {
      throw Errors.unauthenticated('Access token is invalid or expired');
    }

    const { rows } = await db.query<UserRow>(
      `SELECT id, email, full_name, phone, role, account_status, verification_status, created_at
         FROM users WHERE id = $1`,
      [subject],
    );
    const row = rows[0];
    if (!row) {
      throw Errors.unauthenticated('Access token is invalid or expired');
    }
    if (row.account_status !== 'active') {
      throw Errors.accountSuspended();
    }

    req.user = {
      id: row.id,
      email: row.email,
      fullName: row.full_name,
      phone: row.phone,
      role: row.role,
      accountStatus: row.account_status,
      verificationStatus: row.verification_status,
      createdAt: row.created_at,
    };
    next();
  };
}

/** Authorize by role. Must run after `authenticate`. Default-deny. */
export function requireRole(...allowed: Role[]): RequestHandler {
  return (req, _res, next) => {
    if (!req.user) {
      throw Errors.unauthenticated();
    }
    if (!allowed.includes(req.user.role)) {
      throw Errors.forbidden();
    }
    next();
  };
}
