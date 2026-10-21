-- 0002_companies_ipos: company onboarding and the IPO state machine
-- (FR-ONB-01..03, FR-IPO-01..08).
-- Money columns are BIGINT integer minor units of ETB (santim). Never floats.

CREATE TABLE companies (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id       UUID        NOT NULL REFERENCES users (id),
  legal_name          TEXT        NOT NULL,
  registration_number TEXT        NOT NULL,
  description         TEXT,
  onboarding_status   TEXT        NOT NULL DEFAULT 'draft'
                        CHECK (onboarding_status IN ('draft', 'submitted', 'approved', 'rejected')),
  reviewed_by         UUID        REFERENCES users (id),
  reviewed_at         TIMESTAMPTZ,
  rejection_reason    TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- MVP: one company per representative account. Revisit with CompanyMembership.
  CONSTRAINT companies_owner_uniq UNIQUE (owner_user_id),
  CONSTRAINT companies_regno_uniq UNIQUE (registration_number)
);

CREATE TRIGGER companies_set_updated_at
  BEFORE UPDATE ON companies
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE ipos (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id                 UUID        NOT NULL REFERENCES companies (id),
  title                      TEXT        NOT NULL,
  symbol                     TEXT        NOT NULL,
  description                TEXT,
  price_per_share_minor      BIGINT      NOT NULL CHECK (price_per_share_minor > 0),
  total_shares               BIGINT      NOT NULL CHECK (total_shares > 0),
  min_shares_per_subscription BIGINT     NOT NULL DEFAULT 1 CHECK (min_shares_per_subscription > 0),
  max_shares_per_subscription BIGINT     CHECK (max_shares_per_subscription >= min_shares_per_subscription),
  opens_at                   TIMESTAMPTZ NOT NULL,
  closes_at                  TIMESTAMPTZ NOT NULL,
  status                     TEXT        NOT NULL DEFAULT 'draft'
                               CHECK (status IN (
                                 'draft', 'submitted', 'under_review', 'approved', 'open',
                                 'closed', 'allocated', 'listed', 'rejected', 'withdrawn')),
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT ipos_window_valid CHECK (closes_at > opens_at),
  CONSTRAINT ipos_symbol_uniq UNIQUE (symbol)
);

CREATE INDEX ipos_status_idx ON ipos (status);
CREATE INDEX ipos_company_idx ON ipos (company_id);

CREATE TRIGGER ipos_set_updated_at
  BEFORE UPDATE ON ipos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Every status change is recorded (FR-IPO-08).
CREATE TABLE ipo_status_history (
  id          BIGSERIAL PRIMARY KEY,
  ipo_id      UUID        NOT NULL REFERENCES ipos (id),
  from_status TEXT,
  to_status   TEXT        NOT NULL,
  changed_by  UUID        REFERENCES users (id),
  reason      TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ipo_status_history_ipo_idx ON ipo_status_history (ipo_id, created_at);
