-- 0004: subscriptions, idempotency records and audit events
-- (FR-SUB-01..04, FR-LED-04, FR-ADM-02/03, NFR-FIN-03).
-- Tables are created now so the contract is stable; subscription logic ships in Phase 2.

CREATE TABLE subscriptions (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ipo_id                      UUID        NOT NULL REFERENCES ipos (id),
  investor_id                 UUID        NOT NULL REFERENCES users (id),
  quantity                    BIGINT      NOT NULL CHECK (quantity > 0),
  amount_minor                BIGINT      NOT NULL CHECK (amount_minor > 0),
  allocated_quantity          BIGINT      NOT NULL DEFAULT 0 CHECK (allocated_quantity >= 0),
  status                      TEXT        NOT NULL DEFAULT 'reserved'
                                CHECK (status IN (
                                  'reserved', 'allocated', 'partially_allocated',
                                  'released', 'cancelled')),
  reservation_ledger_entry_id UUID        REFERENCES ledger_entries (id),
  idempotency_key             TEXT        NOT NULL,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT subscriptions_alloc_le_qty CHECK (allocated_quantity <= quantity),
  CONSTRAINT subscriptions_idem_uniq UNIQUE (investor_id, idempotency_key)
);

CREATE INDEX subscriptions_ipo_idx ON subscriptions (ipo_id);
CREATE INDEX subscriptions_investor_idx ON subscriptions (investor_id, created_at DESC);

CREATE TRIGGER subscriptions_set_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Request-level idempotency: same key + same request returns the stored result;
-- same key + different request body is rejected (IDEMPOTENCY_KEY_REUSED).
CREATE TABLE idempotency_records (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID        NOT NULL REFERENCES users (id),
  idempotency_key TEXT        NOT NULL,
  request_hash    TEXT        NOT NULL,
  response_status INTEGER,
  response_body   JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT idempotency_user_key_uniq UNIQUE (user_id, idempotency_key)
);

-- Append-only audit trail of security-relevant and privileged actions.
-- `metadata` must never contain passwords, tokens or secrets (FR-ADM-05).
CREATE TABLE audit_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID        REFERENCES users (id),
  actor_role    TEXT,
  action        TEXT        NOT NULL,
  target_type   TEXT,
  target_id     TEXT,
  outcome       TEXT        NOT NULL CHECK (outcome IN ('success', 'failure', 'denied')),
  request_id    TEXT,
  metadata      JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX audit_events_created_idx ON audit_events (created_at DESC);
CREATE INDEX audit_events_actor_idx ON audit_events (actor_user_id, created_at DESC);
CREATE INDEX audit_events_action_idx ON audit_events (action, created_at DESC);

CREATE TRIGGER audit_events_no_update
  BEFORE UPDATE OR DELETE ON audit_events
  FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

CREATE TRIGGER audit_events_no_truncate
  BEFORE TRUNCATE ON audit_events
  FOR EACH STATEMENT EXECUTE FUNCTION forbid_mutation();
