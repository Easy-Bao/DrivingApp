CREATE TABLE bid_sessions (
    id serial PRIMARY KEY,
    passenger_id integer NOT NULL,
    ride_type text NOT NULL DEFAULT 'Solo Ride',
    pickup_latitude double precision NOT NULL,
    pickup_longitude double precision NOT NULL,
    pickup_name text NOT NULL,
    dropoff_latitude double precision NOT NULL,
    dropoff_longitude double precision NOT NULL,
    dropoff_name text NOT NULL,
    passenger_note text,
    distance_km double precision NOT NULL,
    duration_minutes double precision NOT NULL,
    offered_fare_centavos bigint NOT NULL,
    status text NOT NULL DEFAULT 'open',
    target_driver_id integer,
    accepted_driver_id integer,
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX bidsession_expires_at_created_at
    ON bid_sessions (expires_at, created_at);

CREATE INDEX bidsession_target_driver_id_created_at
    ON bid_sessions (target_driver_id, created_at);

CREATE UNIQUE INDEX bidsession_passenger_id
    ON bid_sessions (passenger_id)
    WHERE status = 'open';
