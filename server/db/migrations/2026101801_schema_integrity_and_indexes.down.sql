ALTER TABLE public.wallet_ledgers
    DROP CONSTRAINT IF EXISTS wallet_ledgers_idempotency_key_required;

ALTER TABLE public.wallet_ledgers
    ADD CONSTRAINT wallet_ledgers_idempotency_key_required
    CHECK (idempotency_key IS NOT NULL) NOT VALID;
