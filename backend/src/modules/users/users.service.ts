import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';

/** Public shape of a user (never includes the password hash). */
export interface UserDto {
  id: string;
  email: string;
  full_name: string;
  phone: string | null;
  role: AuthUser['role'];
  account_status: AuthUser['accountStatus'];
  verification_status: AuthUser['verificationStatus'];
  created_at: string;
}

export function toUserDto(u: AuthUser): UserDto {
  return {
    id: u.id,
    email: u.email,
    full_name: u.fullName,
    phone: u.phone,
    role: u.role,
    account_status: u.accountStatus,
    verification_status: u.verificationStatus,
    created_at: u.createdAt.toISOString(),
  };
}

export interface ProfileUpdate {
  full_name?: string;
  phone?: string | null;
}

/**
 * Update the caller's own permitted profile fields (FR-AUTH-05). Role, account status
 * and verification status are NOT updatable here; they change only through admin flows.
 */
export async function updateOwnProfile(
  db: Db,
  user: AuthUser,
  patch: ProfileUpdate,
): Promise<AuthUser> {
  const fullName = patch.full_name ?? user.fullName;
  const phone = patch.phone === undefined ? user.phone : patch.phone;
  await db.query('UPDATE users SET full_name = $2, phone = $3 WHERE id = $1', [
    user.id,
    fullName,
    phone,
  ]);
  return { ...user, fullName, phone };
}
