import type { Logger } from 'pino';
import type { Env } from '../config/env.js';
import type { Db } from '../db/pool.js';
import type { AiProvider } from '../modules/ai/providers/types.js';

export type Role = 'investor' | 'company_rep' | 'broker' | 'admin';
export type AccountStatus = 'active' | 'suspended';
export type VerificationStatus = 'unverified' | 'pending' | 'verified' | 'rejected';

/** The authenticated caller. Always loaded from the database, never from the token. */
export interface AuthUser {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  role: Role;
  accountStatus: AccountStatus;
  verificationStatus: VerificationStatus;
  createdAt: Date;
}

export interface AppDeps {
  env: Env;
  db: Db;
  logger: Logger;
  aiProvider?: AiProvider;
}

declare global {
  // Express's documented way to extend the Request type.
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      requestId: string;
      user?: AuthUser;
    }
  }
}
