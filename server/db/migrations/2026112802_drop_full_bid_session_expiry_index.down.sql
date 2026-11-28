CREATE INDEX CONCURRENTLY bidsession_expires_at_created_at
    ON bid_sessions (expires_at, created_at);
