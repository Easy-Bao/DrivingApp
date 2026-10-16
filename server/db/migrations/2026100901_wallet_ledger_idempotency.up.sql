ALTER TABLE wallet_ledgers
    ADD COLUMN idempotency_key text;

ALTER TABLE wallet_ledgers
    ALTER COLUMN idempotency_key SET DEFAULT gen_random_uuid()::text;

ALTER TABLE wallet_ledgers
    ADD CONSTRAINT wallet_ledgers_idempotency_key_required
    CHECK (idempotency_key IS NOT NULL) NOT VALID;
