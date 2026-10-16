CREATE INDEX CONCURRENTLY IF NOT EXISTS bidsession_passenger_id_status_expires_at
    ON bid_sessions (passenger_id, status, expires_at);
