-- 0001_users: accounts, roles, and account/verification status (FR-AUTH-06).
-- Role, account status and verification status are separate columns on purpose.

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE users (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email               TEXT        NOT NULL,
  password_hash       TEXT        NOT NULL,
  full_name           TEXT        NOT NULL,
  phone               TEXT,
  role                TEXT        NOT NULL
                        CHECK (role IN ('investor', 'company_rep', 'broker', 'admin')),
  account_status      TEXT        NOT NULL DEFAULT 'active'
                        CHECK (account_status IN ('active', 'suspended')),
  verification_status TEXT        NOT NULL DEFAULT 'unverified'
                        CHECK (verification_status IN ('unverified', 'pending', 'verified', 'rejected')),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Emails are unique case-insensitively.
CREATE UNIQUE INDEX users_email_lower_uidx ON users (lower(email));
CREATE INDEX users_role_idx ON users (role);

CREATE TRIGGER users_set_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
