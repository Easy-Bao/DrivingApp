ALTER TABLE wallet_ledgers ALTER COLUMN idempotency_key SET NOT NULL;
ALTER TABLE wallet_ledgers DROP CONSTRAINT wallet_ledgers_idempotency_key_required;
