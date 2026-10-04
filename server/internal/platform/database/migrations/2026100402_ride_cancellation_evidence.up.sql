ALTER TABLE rides
    ADD COLUMN IF NOT EXISTS cancelled_by integer,
    ADD COLUMN IF NOT EXISTS cancellation_reason text NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS cancellation_responsibility text NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS cancellation_details text NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS ride_events (
    id bigserial PRIMARY KEY,
    ride_id integer NOT NULL,
    actor_id integer NOT NULL,
    event_type text NOT NULL,
    from_status text NOT NULL,
    to_status text NOT NULL,
    reason text NOT NULL DEFAULT '',
    responsibility text NOT NULL DEFAULT '',
    details text NOT NULL DEFAULT '',
    request_id text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ride_events_details_length_check CHECK (char_length(details) <= 500)
);

CREATE INDEX IF NOT EXISTS ride_events_ride_id_created_at
    ON ride_events (ride_id, created_at, id);

CREATE INDEX IF NOT EXISTS ride_events_type_created_at
    ON ride_events (event_type, created_at);

DO $migration$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'rides_cancellation_responsibility_check'
          AND conrelid = 'rides'::regclass
    ) THEN
        ALTER TABLE rides
            ADD CONSTRAINT rides_cancellation_responsibility_check
            CHECK (
                cancellation_responsibility IN (
                    '', 'passenger_fault', 'driver_fault', 'system_fault',
                    'no_fault', 'safety_related', 'pending_review', 'admin_override'
                )
            );
    END IF;
END
$migration$;
