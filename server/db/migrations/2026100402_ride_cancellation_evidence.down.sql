DROP INDEX IF EXISTS ride_events_type_created_at;
DROP INDEX IF EXISTS ride_events_ride_id_created_at;
DROP TABLE IF EXISTS ride_events;

ALTER TABLE rides
    DROP CONSTRAINT IF EXISTS rides_cancellation_responsibility_check,
    DROP COLUMN IF EXISTS cancellation_details,
    DROP COLUMN IF EXISTS cancellation_responsibility,
    DROP COLUMN IF EXISTS cancellation_reason,
    DROP COLUMN IF EXISTS cancelled_by;
