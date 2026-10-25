-- 0006_company_ipo_workflow_and_broker_trading.sql
-- Supports:
-- 1. Company IPO draft creation, document uploads, and administrative review.
-- 2. Broker client relationships and authorized client management.
-- 3. Simulated secondary-market share holdings, orders, and trade executions.

-- 1. Extend supporting_documents to support offering documents attached to IPOs
ALTER TABLE supporting_documents DROP CONSTRAINT IF EXISTS supporting_documents_entity_type_check;
ALTER TABLE supporting_documents ADD CONSTRAINT supporting_documents_entity_type_check
  CHECK (entity_type IN ('company', 'broker', 'ipo'));

-- 2. Extend ipos with administrative review feedback fields
ALTER TABLE ipos
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
  ADD COLUMN IF NOT EXISTS review_notes TEXT;

-- 3. Broker-client authorized relationships
CREATE TABLE IF NOT EXISTS broker_client_relationships (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broker_id           UUID NOT NULL REFERENCES brokers (id),
  investor_id         UUID NOT NULL REFERENCES users (id),
  relationship_type   TEXT NOT NULL DEFAULT 'advisory'
                        CHECK (relationship_type IN ('advisory', 'discretionary', 'execution_only')),
  status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'active', 'rejected', 'revoked')),
  notes               TEXT,
  requested_by        TEXT NOT NULL DEFAULT 'broker' CHECK (requested_by IN ('broker', 'investor')),
  requested_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT broker_investor_uniq UNIQUE (broker_id, investor_id)
);

CREATE INDEX IF NOT EXISTS bcr_broker_idx ON broker_client_relationships (broker_id, status);
CREATE INDEX IF NOT EXISTS bcr_investor_idx ON broker_client_relationships (investor_id, status);

CREATE TRIGGER broker_client_rel_set_updated_at
  BEFORE UPDATE ON broker_client_relationships
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4. Share holdings for secondary-market trading and portfolio tracking
CREATE TABLE IF NOT EXISTS share_holdings (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  investor_id         UUID NOT NULL REFERENCES users (id),
  ipo_id              UUID NOT NULL REFERENCES ipos (id),
  quantity            BIGINT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reserved_quantity   BIGINT NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0 AND reserved_quantity <= quantity),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT share_holdings_investor_ipo_uniq UNIQUE (investor_id, ipo_id)
);

CREATE INDEX IF NOT EXISTS share_holdings_investor_idx ON share_holdings (investor_id);
CREATE INDEX IF NOT EXISTS share_holdings_ipo_idx ON share_holdings (ipo_id);

CREATE TRIGGER share_holdings_set_updated_at
  BEFORE UPDATE ON share_holdings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 5. Orders for secondary-market trading
CREATE TABLE IF NOT EXISTS orders (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                UUID NOT NULL REFERENCES users (id),
  assisted_by_broker_id  UUID REFERENCES brokers (id),
  ipo_id                 UUID NOT NULL REFERENCES ipos (id),
  side                   TEXT NOT NULL CHECK (side IN ('buy', 'sell')),
  order_type             TEXT NOT NULL DEFAULT 'limit' CHECK (order_type IN ('limit', 'market')),
  price_per_share_minor  BIGINT NOT NULL CHECK (price_per_share_minor > 0),
  quantity               BIGINT NOT NULL CHECK (quantity > 0),
  filled_quantity        BIGINT NOT NULL DEFAULT 0 CHECK (filled_quantity >= 0 AND filled_quantity <= quantity),
  status                 TEXT NOT NULL DEFAULT 'open'
                           CHECK (status IN ('open', 'partially_filled', 'filled', 'cancelled', 'rejected')),
  reserved_amount_minor  BIGINT NOT NULL DEFAULT 0 CHECK (reserved_amount_minor >= 0),
  is_simulated           BOOLEAN NOT NULL DEFAULT true,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS orders_user_idx ON orders (user_id, status);
CREATE INDEX IF NOT EXISTS orders_ipo_side_status_idx ON orders (ipo_id, side, status, price_per_share_minor, created_at);

CREATE TRIGGER orders_set_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 6. Trades (executed order matches)
CREATE TABLE IF NOT EXISTS trades (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buy_order_id          UUID NOT NULL REFERENCES orders (id),
  sell_order_id         UUID NOT NULL REFERENCES orders (id),
  ipo_id                UUID NOT NULL REFERENCES ipos (id),
  buyer_user_id         UUID NOT NULL REFERENCES users (id),
  seller_user_id        UUID NOT NULL REFERENCES users (id),
  price_per_share_minor BIGINT NOT NULL CHECK (price_per_share_minor > 0),
  quantity              BIGINT NOT NULL CHECK (quantity > 0),
  total_amount_minor    BIGINT NOT NULL CHECK (total_amount_minor > 0),
  is_simulated          BOOLEAN NOT NULL DEFAULT true,
  executed_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS trades_ipo_idx ON trades (ipo_id, executed_at DESC);
CREATE INDEX IF NOT EXISTS trades_buyer_idx ON trades (buyer_user_id, executed_at DESC);
CREATE INDEX IF NOT EXISTS trades_seller_idx ON trades (seller_user_id, executed_at DESC);
