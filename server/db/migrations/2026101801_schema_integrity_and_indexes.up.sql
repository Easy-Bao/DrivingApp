UPDATE public.wallet_ledgers
    SET idempotency_key = gen_random_uuid()::text
    WHERE idempotency_key IS NULL;

ALTER TABLE public.wallet_ledgers
    VALIDATE CONSTRAINT wallet_ledgers_idempotency_key_required;
