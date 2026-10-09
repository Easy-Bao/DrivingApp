CREATE TABLE reviews (
    id serial PRIMARY KEY,
    ride_id integer,
    driver_id integer NOT NULL,
    passenger_id integer NOT NULL,
    passenger_name text,
    rating double precision NOT NULL,
    comment text,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (rating BETWEEN 0 AND 5),
    CONSTRAINT reviews_ride_fk
        FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE CASCADE,
    CONSTRAINT reviews_driver_fk
        FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT reviews_passenger_fk
        FOREIGN KEY (passenger_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX review_ride_id
    ON reviews (ride_id)
    WHERE ride_id IS NOT NULL;

CREATE INDEX review_driver_id_created_at
    ON reviews (driver_id, created_at);

CREATE INDEX review_passenger_id_idx
    ON reviews (passenger_id);

CREATE TABLE passenger_reviews (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    driver_id integer NOT NULL,
    passenger_id integer NOT NULL,
    rating double precision NOT NULL,
    comment text,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT passenger_reviews_rating_check CHECK (rating BETWEEN 0 AND 5),
    CONSTRAINT passenger_reviews_ride_fk
        FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE CASCADE,
    CONSTRAINT passenger_reviews_driver_fk
        FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT passenger_reviews_passenger_fk
        FOREIGN KEY (passenger_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX passengerreview_ride_id
    ON passenger_reviews (ride_id);

CREATE INDEX passengerreview_passenger_id_created_at
    ON passenger_reviews (passenger_id, created_at);

CREATE INDEX passengerreview_driver_id_idx
    ON passenger_reviews (driver_id);
