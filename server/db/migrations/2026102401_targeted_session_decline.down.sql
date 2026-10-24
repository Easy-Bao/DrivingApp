UPDATE bid_sessions SET status = 'cancelled' WHERE status = 'declined';
ALTER TABLE bid_sessions DROP CONSTRAINT bid_sessions_status_check;
ALTER TABLE bid_sessions ADD CONSTRAINT bid_sessions_status_check CHECK (status IN ('open', 'accepted', 'cancelled', 'expired'));
