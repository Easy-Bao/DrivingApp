CREATE TABLE ride_settlements (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    gross_fare_centavos bigint NOT NULL,
    commission_bps bigint,
    commission_centavos bigint NOT NULL DEFAULT 0,
    driver_payout_centavos bigint NOT NULL DEFAULT 0,
    payment_status text NOT NULL DEFAULT 'unpaid',
    cash_received_at timestamptz,
    settled_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX ridesettlement_ride_id
    ON ride_settlements (ride_id);

CREATE INDEX ridesettlement_payment_status_updated_at
    ON ride_settlements (payment_status, updated_at);
