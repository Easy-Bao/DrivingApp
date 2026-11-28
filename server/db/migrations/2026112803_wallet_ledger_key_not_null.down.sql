ALTER TABLE wallet_ledgers ADD CONSTRAINT wallet_ledgers_idempotency_key_required
    CHECK (idempotency_key IS NOT NULL);
ALTER TABLE wallet_ledgers ALTER COLUMN idempotency_key DROP NOT NULL;
