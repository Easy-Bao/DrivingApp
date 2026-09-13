CREATE TABLE bid_offers (
    id serial PRIMARY KEY,
    session_id integer NOT NULL,
    driver_id integer NOT NULL,
    driver_name text,
    plate_number text,
    vehicle_type text,
    proposed_fare bigint NOT NULL,
    status text NOT NULL DEFAULT 'pending',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT bid_offers_fare_check CHECK (proposed_fare >= 0)
);

CREATE INDEX bidoffer_session_id_created_at
    ON bid_offers (session_id, created_at);

CREATE UNIQUE INDEX bidoffer_session_id_driver_id
    ON bid_offers (session_id, driver_id)
    WHERE status = 'pending';
