-- 0007_trading_ledger_entries.sql
-- Extends ledger_entries entry_type to support secondary-market simulated trading movements:
-- trade_reserve (cash reserved for buy order)
-- trade_release (cash released upon order cancellation or price-improvement refund)
-- trade_settle (cash paid for executed buy order)
-- trade_credit (cash received for executed sell order)

ALTER TABLE ledger_entries DROP CONSTRAINT IF EXISTS ledger_entries_entry_type_check;
ALTER TABLE ledger_entries ADD CONSTRAINT ledger_entries_entry_type_check CHECK (
  entry_type IN (
    'test_fund_credit',
    'subscription_reserve',
    'subscription_release',
    'subscription_settle',
    'adjustment',
    'trade_reserve',
    'trade_release',
    'trade_settle',
    'trade_credit'
  )
);

-- Shape constraints for secondary-market movements:
ALTER TABLE ledger_entries DROP CONSTRAINT IF EXISTS ledger_trade_reserve_shape;
ALTER TABLE ledger_entries ADD CONSTRAINT ledger_trade_reserve_shape CHECK (
  entry_type <> 'trade_reserve'
  OR (available_delta_minor < 0 AND reserved_delta_minor = -available_delta_minor)
);

ALTER TABLE ledger_entries DROP CONSTRAINT IF EXISTS ledger_trade_release_shape;
ALTER TABLE ledger_entries ADD CONSTRAINT ledger_trade_release_shape CHECK (
  entry_type <> 'trade_release'
  OR (available_delta_minor > 0 AND reserved_delta_minor = -available_delta_minor)
);

ALTER TABLE ledger_entries DROP CONSTRAINT IF EXISTS ledger_trade_settle_shape;
ALTER TABLE ledger_entries ADD CONSTRAINT ledger_trade_settle_shape CHECK (
  entry_type <> 'trade_settle'
  OR (available_delta_minor = 0 AND reserved_delta_minor < 0)
);

ALTER TABLE ledger_entries DROP CONSTRAINT IF EXISTS ledger_trade_credit_shape;
ALTER TABLE ledger_entries ADD CONSTRAINT ledger_trade_credit_shape CHECK (
  entry_type <> 'trade_credit'
  OR (available_delta_minor > 0 AND reserved_delta_minor = 0)
);
