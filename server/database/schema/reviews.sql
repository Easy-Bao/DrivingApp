CREATE TABLE reviews (
    id serial PRIMARY KEY,
    ride_id integer,
    driver_id integer NOT NULL,
    passenger_id integer NOT NULL,
    passenger_name text,
    rating double precision NOT NULL,
    comment text,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX review_ride_id
    ON reviews (ride_id)
    WHERE ride_id IS NOT NULL;

CREATE INDEX review_driver_id_created_at
    ON reviews (driver_id, created_at);

CREATE TABLE passenger_reviews (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    driver_id integer NOT NULL,
    passenger_id integer NOT NULL,
    rating double precision NOT NULL,
    comment text,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX passengerreview_ride_id
    ON passenger_reviews (ride_id);

CREATE INDEX passengerreview_passenger_id_created_at
    ON passenger_reviews (passenger_id, created_at);
