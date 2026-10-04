ALTER TABLE rides
    ADD COLUMN IF NOT EXISTS arrived_at timestamptz,
    ADD COLUMN IF NOT EXISTS waiting_until timestamptz;

CREATE INDEX IF NOT EXISTS rides_waiting_until_idx
    ON rides (status, waiting_until)
    WHERE status = 'arrived';
