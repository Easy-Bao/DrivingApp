CREATE TABLE rides (
    id serial PRIMARY KEY,
    passenger_id integer NOT NULL,
    driver_id integer,
    status text NOT NULL DEFAULT 'requested',
    fare_amount bigint NOT NULL,
    ride_type text NOT NULL DEFAULT 'Solo Ride',
    pickup_latitude double precision,
    pickup_longitude double precision,
    pickup_name text,
    dropoff_latitude double precision,
    dropoff_longitude double precision,
    dropoff_name text,
    distance_km double precision,
    duration_minutes double precision,
    -- Captured at driver assignment so historical rides do not change with profile edits.
    driver_name text,
    vehicle_type text,
    plate_number text,
    driver_rating double precision,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at timestamptz,
    payment_status text NOT NULL DEFAULT 'unpaid',
    cash_received_at timestamptz,
    commission_bps integer,
    commission_amount bigint NOT NULL DEFAULT 0,
    driver_payout_amount bigint NOT NULL DEFAULT 0,
    CONSTRAINT rides_money_check CHECK (
        fare_amount >= 0
        AND commission_amount >= 0
        AND driver_payout_amount >= 0
    ),
    CONSTRAINT rides_route_metrics_check CHECK (
        (distance_km IS NULL OR distance_km >= 0)
        AND (duration_minutes IS NULL OR duration_minutes >= 0)
    ),
    CONSTRAINT rides_coordinates_check CHECK (
        (pickup_latitude IS NULL OR pickup_latitude BETWEEN -90 AND 90)
        AND (pickup_longitude IS NULL OR pickup_longitude BETWEEN -180 AND 180)
        AND (dropoff_latitude IS NULL OR dropoff_latitude BETWEEN -90 AND 90)
        AND (dropoff_longitude IS NULL OR dropoff_longitude BETWEEN -180 AND 180)
    )
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

CREATE UNIQUE INDEX rides_one_active_ride_per_driver_idx
    ON rides (driver_id)
    WHERE driver_id IS NOT NULL
      AND status IN ('assigned', 'accepted', 'arrived', 'in_transit');
