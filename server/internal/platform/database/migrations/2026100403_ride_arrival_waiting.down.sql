DROP INDEX IF EXISTS rides_waiting_until_idx;

ALTER TABLE rides
    DROP COLUMN IF EXISTS waiting_until,
    DROP COLUMN IF EXISTS arrived_at;
