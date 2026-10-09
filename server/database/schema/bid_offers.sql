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
    CONSTRAINT bid_offers_status_check CHECK (status IN ('pending', 'accepted', 'rejected')),
    CONSTRAINT bid_offers_fare_check CHECK (proposed_fare >= 0),
    CONSTRAINT bid_offers_session_fk
        FOREIGN KEY (session_id) REFERENCES bid_sessions (id) ON DELETE CASCADE,
    CONSTRAINT bid_offers_driver_fk
        FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE INDEX bidoffer_session_id_created_at
    ON bid_offers (session_id, created_at);

CREATE INDEX bidoffer_driver_id_idx
    ON bid_offers (driver_id);

CREATE UNIQUE INDEX bidoffer_session_id_driver_id
    ON bid_offers (session_id, driver_id)
    WHERE status = 'pending';
