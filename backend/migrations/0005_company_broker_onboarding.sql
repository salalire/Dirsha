-- 0005_company_broker_onboarding: company and broker onboarding workflows,
-- supporting document storage metadata, and application status history (FR-ONB-01..06, FR-DOC-01..05, FR-BRK-01..05).

-- 1. Extend companies table onboarding status constraint and profile fields
ALTER TABLE companies DROP CONSTRAINT IF EXISTS companies_onboarding_status_check;
ALTER TABLE companies ADD CONSTRAINT companies_onboarding_status_check
  CHECK (onboarding_status IN (
    'draft', 'submitted', 'under_review', 'additional_info_required', 'resubmitted', 'approved', 'rejected'
  ));

ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS trade_name TEXT,
  ADD COLUMN IF NOT EXISTS legal_entity_type TEXT DEFAULT 'plc'
    CHECK (legal_entity_type IN ('plc', 'share_company', 'sole_proprietorship', 'partnership', 'corporation', 'other')),
  ADD COLUMN IF NOT EXISTS country_of_incorporation TEXT NOT NULL DEFAULT 'Ethiopia',
  ADD COLUMN IF NOT EXISTS incorporation_date DATE,
  ADD COLUMN IF NOT EXISTS business_address TEXT,
  ADD COLUMN IF NOT EXISTS operating_address TEXT,
  ADD COLUMN IF NOT EXISTS business_email TEXT,
  ADD COLUMN IF NOT EXISTS business_phone TEXT,
  ADD COLUMN IF NOT EXISTS website TEXT,
  ADD COLUMN IF NOT EXISTS industry_sector TEXT,
  ADD COLUMN IF NOT EXISTS tin TEXT,
  ADD COLUMN IF NOT EXISTS vat_number TEXT,
  ADD COLUMN IF NOT EXISTS representative_name TEXT,
  ADD COLUMN IF NOT EXISTS representative_email TEXT,
  ADD COLUMN IF NOT EXISTS representative_phone TEXT,
  ADD COLUMN IF NOT EXISTS representative_title TEXT,
  ADD COLUMN IF NOT EXISTS representative_role_description TEXT,
  ADD COLUMN IF NOT EXISTS authority_declaration BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS review_notes TEXT,
  ADD COLUMN IF NOT EXISTS additional_info_request TEXT;

-- 2. Create brokers table
CREATE TABLE IF NOT EXISTS brokers (
  id                             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id                  UUID NOT NULL REFERENCES users (id),
  broker_type                    TEXT NOT NULL DEFAULT 'firm' CHECK (broker_type IN ('individual', 'firm')),
  legal_name                     TEXT NOT NULL,
  trade_name                     TEXT,
  registration_number            TEXT,
  tin                            TEXT,
  business_address               TEXT,
  city                           TEXT NOT NULL DEFAULT 'Addis Ababa',
  country                        TEXT NOT NULL DEFAULT 'Ethiopia',
  business_email                 TEXT,
  business_phone                 TEXT,
  website                        TEXT,
  license_number                 TEXT NOT NULL,
  license_category               TEXT NOT NULL, -- e.g. securities_broker, investment_advisor, dealing_broker
  licensing_authority            TEXT NOT NULL DEFAULT 'Ethiopian Capital Market Authority (ECMA)',
  license_issued_date            DATE,
  license_expiry_date            DATE NOT NULL,
  representative_name            TEXT,
  representative_email           TEXT,
  representative_phone           TEXT,
  representative_title           TEXT,
  authority_declaration          BOOLEAN NOT NULL DEFAULT false,
  onboarding_status              TEXT NOT NULL DEFAULT 'draft'
                                   CHECK (onboarding_status IN (
                                     'draft', 'submitted', 'under_review', 'additional_info_required', 'resubmitted', 'approved', 'rejected'
                                   )),
  reviewed_by                    UUID REFERENCES users (id),
  reviewed_at                    TIMESTAMPTZ,
  rejection_reason               TEXT,
  review_notes                   TEXT,
  additional_info_request        TEXT,
  created_at                     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT brokers_owner_uniq UNIQUE (owner_user_id),
  CONSTRAINT brokers_license_uniq UNIQUE (license_number)
);

CREATE INDEX IF NOT EXISTS brokers_status_idx ON brokers (onboarding_status);
CREATE INDEX IF NOT EXISTS brokers_owner_idx ON brokers (owner_user_id);

CREATE TRIGGER brokers_set_updated_at
  BEFORE UPDATE ON brokers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE brokers ALTER COLUMN business_address DROP NOT NULL;
ALTER TABLE brokers ALTER COLUMN business_email DROP NOT NULL;
ALTER TABLE brokers ALTER COLUMN business_phone DROP NOT NULL;

-- 3. Supporting documents table (metadata for private document storage)
CREATE TABLE IF NOT EXISTS supporting_documents (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id       UUID NOT NULL REFERENCES users (id),
  entity_type         TEXT NOT NULL CHECK (entity_type IN ('company', 'broker')),
  entity_id           UUID NOT NULL,
  document_type       TEXT NOT NULL, -- e.g. commercial_registration, tin_certificate, memorandum, broker_license
  file_name           TEXT NOT NULL,
  file_size_bytes     BIGINT NOT NULL CHECK (file_size_bytes > 0),
  mime_type           TEXT NOT NULL,
  storage_key         TEXT NOT NULL,
  review_status       TEXT NOT NULL DEFAULT 'pending' CHECK (review_status IN ('pending', 'approved', 'rejected')),
  review_notes        TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS supporting_docs_entity_idx ON supporting_documents (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS supporting_docs_owner_idx ON supporting_documents (owner_user_id);

CREATE TRIGGER supporting_docs_set_updated_at
  BEFORE UPDATE ON supporting_documents
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4. Application status history (immutable transition audit log)
CREATE TABLE IF NOT EXISTS application_status_history (
  id            BIGSERIAL PRIMARY KEY,
  entity_type   TEXT NOT NULL CHECK (entity_type IN ('company', 'broker')),
  entity_id     UUID NOT NULL,
  from_status   TEXT,
  to_status     TEXT NOT NULL,
  changed_by    UUID REFERENCES users (id),
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS app_status_hist_entity_idx ON application_status_history (entity_type, entity_id, created_at DESC);
