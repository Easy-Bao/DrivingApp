CREATE TABLE bids (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    driver_id integer NOT NULL,
    offered_fare_centavos bigint NOT NULL,
    status text NOT NULL DEFAULT 'pending'
);

CREATE UNIQUE INDEX bid_ride_id_driver_id
    ON bids (ride_id, driver_id)
    WHERE status = 'pending';
