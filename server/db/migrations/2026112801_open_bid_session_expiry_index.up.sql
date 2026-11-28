CREATE INDEX CONCURRENTLY bid_sessions_open_expiry_id_idx
    ON bid_sessions (expires_at, id) WHERE status = 'open';
