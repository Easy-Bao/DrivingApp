CREATE INDEX CONCURRENTLY wallet_ledgers_ride_kind_idx
    ON wallet_ledgers (ride_id, kind);
