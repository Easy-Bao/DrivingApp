CREATE UNIQUE INDEX CONCURRENTLY wallet_ledgers_idempotency_key_uidx
    ON wallet_ledgers (idempotency_key);
