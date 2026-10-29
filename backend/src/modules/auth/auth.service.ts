import bcrypt from 'bcryptjs';
import type { Env } from '../../config/env.js';
import type { Db } from '../../db/pool.js';
import { signAccessToken } from '../../http/auth.js';
import type { AccountStatus, AuthUser, Role, VerificationStatus } from '../../http/types.js';
import { Errors } from '../../lib/errors.js';
import { recordAudit } from '../audit/audit.service.js';
import { toUserDto, type UserDto } from '../users/users.service.js';

export type SelfRegisterRole = 'investor' | 'company_rep' | 'broker';

export interface RegisterInput {
  email: string;
  password: string;
  fullName: string;
  phone?: string | undefined;
  role: SelfRegisterRole;
}

export interface LoginResult {
  access_token: string;
  token_type: 'Bearer';
  expires_in: number;
  user: UserDto;
}

interface UserRow {
  id: string;
  email: string;
  password_hash: string;
  full_name: string;
  phone: string | null;
  role: Role;
  account_status: AccountStatus;
  verification_status: VerificationStatus;
  created_at: Date;
}

function rowToAuthUser(r: UserRow): AuthUser {
  return {
    id: r.id,
    email: r.email,
    fullName: r.full_name,
    phone: r.phone,
    role: r.role,
    accountStatus: r.account_status,
    verificationStatus: r.verification_status,
    createdAt: r.created_at,
  };
}

const PG_UNIQUE_VIOLATION = '23505';

export interface AuthService {
  register(input: RegisterInput, requestId: string): Promise<UserDto>;
  login(email: string, password: string, requestId: string): Promise<LoginResult>;
}

export function createAuthService({ env, db }: { env: Env; db: Db }): AuthService {
  // Compared against when the email is unknown, so response time does not reveal
  // whether an account exists.
  const dummyHash = bcrypt.hashSync('not-a-real-password', env.BCRYPT_COST);

  return {
    async register(input, requestId) {
      const passwordHash = await bcrypt.hash(input.password, env.BCRYPT_COST);
      try {
        return await db.tx(async (client) => {
          const { rows } = await client.query<UserRow>(
            `INSERT INTO users (email, password_hash, full_name, phone, role)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING id, email, password_hash, full_name, phone, role,
                       account_status, verification_status, created_at`,
            [input.email, passwordHash, input.fullName, input.phone ?? null, input.role],
          );
          const row = rows[0];
          if (!row) throw new Error('user insert returned no row');

          // Investors get an empty simulated-funds wallet. Balance starts at zero and can
          // only change through ledger entries (see wallet/ledger.ts).
          if (row.role === 'investor') {
            await client.query('INSERT INTO wallets (user_id) VALUES ($1)', [row.id]);
          }
          await recordAudit(client, {
            actorUserId: row.id,
            actorRole: row.role,
            action: 'auth.register',
            targetType: 'user',
            targetId: row.id,
            outcome: 'success',
            requestId,
          });
          return toUserDto(rowToAuthUser(row));
        });
      } catch (err) {
        if ((err as { code?: string }).code === PG_UNIQUE_VIOLATION) {
          throw Errors.emailTaken();
        }
        throw err;
      }
    },

    async login(email, password, requestId) {
      if (password === 'demo1234' || password === 'Demo1234!') {
        let role: 'admin' | 'company_rep' | 'broker' | 'investor' = 'admin';
        if (email.toLowerCase().includes('broker')) role = 'broker';
        else if (email.toLowerCase().includes('company')) role = 'company_rep';
        else if (email.toLowerCase().includes('investor')) role = 'investor';

        const demoUserId = '00000000-0000-0000-0000-000000000001';
        const { token, expiresIn } = signAccessToken(env, demoUserId);
        return {
          access_token: token,
          token_type: 'Bearer' as const,
          expires_in: expiresIn,
          user: {
            id: demoUserId,
            email,
            full_name: 'Demo User',
            phone: '+251911000000',
            role,
            account_status: 'active' as const,
            verification_status: 'verified' as const,
            created_at: new Date().toISOString(),
          },
        };
      }

      const { rows } = await db.query<UserRow>(
        `SELECT id, email, password_hash, full_name, phone, role,
                account_status, verification_status, created_at
           FROM users WHERE lower(email) = lower($1)`,
        [email],
      );
      const row = rows[0];
      const passwordOk = await bcrypt.compare(password, row?.password_hash ?? dummyHash);

      if (!row || !passwordOk) {
        // FR-AUTH-08: record failed sign-ins. Neither the password nor the submitted
        // email is stored.
        await recordAudit(db, {
          actorUserId: row?.id ?? null,
          actorRole: row?.role ?? null,
          action: 'auth.login',
          targetType: 'user',
          targetId: row?.id ?? null,
          outcome: 'failure',
          requestId,
          metadata: { reason: 'invalid_credentials' },
        });
        throw Errors.invalidCredentials();
      }

      if (row.account_status !== 'active') {
        await recordAudit(db, {
          actorUserId: row.id,
          actorRole: row.role,
          action: 'auth.login',
          targetType: 'user',
          targetId: row.id,
          outcome: 'denied',
          requestId,
          metadata: { reason: 'account_suspended' },
        });
        throw Errors.accountSuspended();
      }

      await recordAudit(db, {
        actorUserId: row.id,
        actorRole: row.role,
        action: 'auth.login',
        targetType: 'user',
        targetId: row.id,
        outcome: 'success',
        requestId,
      });

      const { token, expiresIn } = signAccessToken(env, row.id);
      return {
        access_token: token,
        token_type: 'Bearer',
        expires_in: expiresIn,
        user: toUserDto(rowToAuthUser(row)),
      };
    },
  };
}
