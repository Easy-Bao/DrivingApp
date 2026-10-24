ALTER TABLE bid_sessions DROP CONSTRAINT bid_sessions_status_check;
ALTER TABLE bid_sessions ADD CONSTRAINT bid_sessions_status_check CHECK (status IN ('open', 'accepted', 'cancelled', 'expired', 'declined'));
