CREATE INDEX CONCURRENTLY IF NOT EXISTS bidsession_accepted_driver_id_idx
    ON bid_sessions (accepted_driver_id)
    WHERE accepted_driver_id IS NOT NULL;
