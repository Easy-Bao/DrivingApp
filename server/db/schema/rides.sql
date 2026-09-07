CREATE TABLE rides (
    id serial PRIMARY KEY,
    passenger_id integer NOT NULL,
    driver_id integer,
    status text NOT NULL DEFAULT 'requested',
    fare_centavos bigint NOT NULL,
    ride_type text NOT NULL DEFAULT 'Solo Ride',
    pickup_latitude double precision,
    pickup_longitude double precision,
    pickup_name text,
    dropoff_latitude double precision,
    dropoff_longitude double precision,
    dropoff_name text,
    distance_km double precision,
    duration_minutes double precision,
    driver_name text,
    vehicle_type text,
    plate_number text,
    driver_rating double precision,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at timestamptz,
    payment_status text NOT NULL DEFAULT 'unpaid',
    cash_received_at timestamptz,
    commission_bps bigint,
    commission_centavos bigint NOT NULL DEFAULT 0,
    driver_payout_centavos bigint NOT NULL DEFAULT 0
);

CREATE INDEX ride_passenger_id_created_at
    ON rides (passenger_id, created_at);

CREATE INDEX ride_passenger_id_status_completed_at
    ON rides (passenger_id, status, completed_at);

CREATE INDEX ride_driver_id_created_at
    ON rides (driver_id, created_at);

CREATE INDEX ride_driver_id_status_completed_at
    ON rides (driver_id, status, completed_at);

CREATE UNIQUE INDEX ride_passenger_id
    ON rides (passenger_id)
    WHERE status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit');
