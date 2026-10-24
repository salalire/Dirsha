-- 0005: Phase 2 rules for subscriptions (docs/BUSINESS_RULES.md B4, B6-B9).
-- Additive only: 0001-0004 are already applied on developers' machines and are checksummed.

-- B4: an investor has at most ONE active subscription per IPO. "Active" = still counts
-- toward the offering. A cancelled or fully released subscription frees the slot.
-- This is the last line of defence against two concurrent requests both passing the
-- application-level check.
CREATE UNIQUE INDEX subscriptions_one_active_per_ipo_uidx
  ON subscriptions (ipo_id, investor_id)
  WHERE status IN ('reserved', 'allocated', 'partially_allocated');

-- Allocation and summaries read all subscriptions of one IPO by status.
CREATE INDEX subscriptions_ipo_status_idx ON subscriptions (ipo_id, status);

-- Once an IPO has been allocated, a subscription's outcome is final: it can never move
-- back to 'reserved' (which would let funds be settled or released twice).
CREATE OR REPLACE FUNCTION subscriptions_forbid_reopen() RETURNS trigger AS $$
BEGIN
  IF OLD.status <> 'reserved' AND NEW.status = 'reserved' THEN
    RAISE EXCEPTION 'subscription % cannot return to reserved from %', OLD.id, OLD.status
      USING ERRCODE = 'restrict_violation';
  END IF;
  IF OLD.status <> 'reserved' AND NEW.status <> OLD.status THEN
    RAISE EXCEPTION 'subscription % is already final (%)', OLD.id, OLD.status
      USING ERRCODE = 'restrict_violation';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscriptions_status_is_final
  BEFORE UPDATE OF status ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION subscriptions_forbid_reopen();
