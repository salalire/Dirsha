import bcrypt from 'bcryptjs';
import type { Db } from '../../db/pool.js';
import { Errors } from '../../lib/errors.js';
import { recordAudit } from '../audit/audit.service.js';

export const MIN_ADMIN_PASSWORD_LENGTH = 12;
const PG_UNIQUE_VIOLATION = '23505';

/**
 * Out-of-band creation of an administrator account (public registration can never
 * create one). Used by `npm run create-admin`, which reads the credentials from
 * environment variables so nothing sensitive is written to Git or shell history files
 * by the tool itself. The action is audited.
 */
export async function createAdminAccount(
  db: Db,
  input: { email: string; password: string; fullName: string; bcryptCost: number },
): Promise<{ id: string; email: string }> {
  const email = input.email.trim();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 254) {
    throw Errors.validation([{ field: 'email', message: 'Invalid email address' }]);
  }
  if (input.password.length < MIN_ADMIN_PASSWORD_LENGTH) {
    throw Errors.validation([
      { field: 'password', message: `Admin password must be at least ${MIN_ADMIN_PASSWORD_LENGTH} characters` },
    ]);
  }
  if (Buffer.byteLength(input.password, 'utf8') > 72) {
    throw Errors.validation([{ field: 'password', message: 'Password must be at most 72 bytes' }]);
  }

  const hash = await bcrypt.hash(input.password, input.bcryptCost);
  try {
    return await db.tx(async (client) => {
      const { rows } = await client.query<{ id: string; email: string }>(
        `INSERT INTO users (email, password_hash, full_name, role, verification_status)
         VALUES ($1, $2, $3, 'admin', 'verified')
         RETURNING id, email`,
        [email, hash, input.fullName],
      );
      const row = rows[0];
      if (!row) throw new Error('admin insert returned no row');
      await recordAudit(client, {
        actorUserId: null,
        actorRole: null,
        action: 'admin.provisioned',
        targetType: 'user',
        targetId: row.id,
        outcome: 'success',
        metadata: { via: 'cli' },
      });
      return row;
    });
  } catch (err) {
    if ((err as { code?: string }).code === PG_UNIQUE_VIOLATION) {
      throw Errors.emailTaken();
    }
    throw err;
  }
}
