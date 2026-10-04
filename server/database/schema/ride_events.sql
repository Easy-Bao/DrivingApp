CREATE TABLE ride_events (
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

CREATE INDEX ride_events_ride_id_created_at
    ON ride_events (ride_id, created_at, id);

CREATE INDEX ride_events_type_created_at
    ON ride_events (event_type, created_at);
