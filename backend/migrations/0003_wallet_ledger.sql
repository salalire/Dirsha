-- 0003_wallet_ledger: ledger-backed internal wallet using SIMULATED funds
-- (FR-LED-01..07, NFR-FIN-01..04).
--
-- Model (documented in docs/BUSINESS_RULES.md):
--   * ledger_entries is the append-only source of truth for every fund movement.
--   * wallets.available_minor / reserved_minor are a transactionally-maintained
--     running balance. The view wallet_reconciliation proves they equal the ledger sums.
--   * No client can set a balance; only backend code writes ledger entries and wallets
--     together inside one transaction.

CREATE TABLE wallets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID        NOT NULL REFERENCES users (id),
  currency        TEXT        NOT NULL DEFAULT 'ETB' CHECK (currency = 'ETB'),
  available_minor BIGINT      NOT NULL DEFAULT 0 CHECK (available_minor >= 0),
  reserved_minor  BIGINT      NOT NULL DEFAULT 0 CHECK (reserved_minor >= 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT wallets_user_uniq UNIQUE (user_id)
);

CREATE TRIGGER wallets_set_updated_at
  BEFORE UPDATE ON wallets
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE ledger_entries (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id             UUID        NOT NULL REFERENCES wallets (id),
  entry_type            TEXT        NOT NULL CHECK (entry_type IN (
                          'test_fund_credit',      -- simulated funds credited (dev/test only)
                          'subscription_reserve',  -- available -> reserved
                          'subscription_release',  -- reserved -> available (unused / cancelled)
                          'subscription_settle',   -- reserved -> paid to the offering (leaves wallet)
                          'adjustment')),          -- correction-linked entry, admin-only, audited
  available_delta_minor BIGINT      NOT NULL,
  reserved_delta_minor  BIGINT      NOT NULL,
  available_after_minor BIGINT      NOT NULL CHECK (available_after_minor >= 0),
  reserved_after_minor  BIGINT      NOT NULL CHECK (reserved_after_minor >= 0),
  status                TEXT        NOT NULL DEFAULT 'posted' CHECK (status IN ('posted')),
  reference_type        TEXT,                -- e.g. 'subscription'
  reference_id          UUID,                -- business reference (subscription id, ...)
  idempotency_key       TEXT,
  initiated_by_user_id  UUID        REFERENCES users (id),
  initiated_by_type     TEXT        NOT NULL CHECK (initiated_by_type IN ('user', 'admin', 'system')),
  description           TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Shape of each movement type is enforced by the database, not just by app code.
  CONSTRAINT ledger_credit_shape CHECK (
    entry_type <> 'test_fund_credit' OR (available_delta_minor > 0 AND reserved_delta_minor = 0)),
  CONSTRAINT ledger_reserve_shape CHECK (
    entry_type <> 'subscription_reserve'
    OR (available_delta_minor < 0 AND reserved_delta_minor = -available_delta_minor)),
  CONSTRAINT ledger_release_shape CHECK (
    entry_type <> 'subscription_release'
    OR (available_delta_minor > 0 AND reserved_delta_minor = -available_delta_minor)),
  CONSTRAINT ledger_settle_shape CHECK (
    entry_type <> 'subscription_settle'
    OR (available_delta_minor = 0 AND reserved_delta_minor < 0)),
  CONSTRAINT ledger_nonzero CHECK (available_delta_minor <> 0 OR reserved_delta_minor <> 0)
);

CREATE INDEX ledger_entries_wallet_idx ON ledger_entries (wallet_id, created_at DESC);
CREATE INDEX ledger_entries_ref_idx ON ledger_entries (reference_type, reference_id);

-- A retried operation with the same key can never post the same entry type twice per wallet.
CREATE UNIQUE INDEX ledger_entries_idem_uidx
  ON ledger_entries (wallet_id, entry_type, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- Ledger history is immutable: corrections are new, linked entries (FR-LED-02).
CREATE OR REPLACE FUNCTION forbid_mutation() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION '% on % is not allowed: this table is append-only', TG_OP, TG_TABLE_NAME
    USING ERRCODE = 'restrict_violation';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ledger_entries_no_update
  BEFORE UPDATE OR DELETE ON ledger_entries
  FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

CREATE TRIGGER ledger_entries_no_truncate
  BEFORE TRUNCATE ON ledger_entries
  FOR EACH STATEMENT EXECUTE FUNCTION forbid_mutation();

-- Reconciliation: stored balance vs. ledger sums. Any row with ok = false is a defect.
CREATE VIEW wallet_reconciliation AS
SELECT
  w.id                                              AS wallet_id,
  w.available_minor                                 AS wallet_available_minor,
  w.reserved_minor                                  AS wallet_reserved_minor,
  COALESCE(SUM(l.available_delta_minor), 0)::BIGINT AS ledger_available_minor,
  COALESCE(SUM(l.reserved_delta_minor), 0)::BIGINT  AS ledger_reserved_minor,
  (w.available_minor = COALESCE(SUM(l.available_delta_minor), 0)
   AND w.reserved_minor = COALESCE(SUM(l.reserved_delta_minor), 0)) AS ok
FROM wallets w
LEFT JOIN ledger_entries l ON l.wallet_id = w.id
GROUP BY w.id;
