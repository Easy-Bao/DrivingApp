ALTER TABLE wallet_ledgers
    DROP CONSTRAINT IF EXISTS wallet_ledgers_idempotency_key_required;

ALTER TABLE wallet_ledgers
    ALTER COLUMN idempotency_key DROP DEFAULT;

ALTER TABLE wallet_ledgers
    DROP COLUMN idempotency_key;
