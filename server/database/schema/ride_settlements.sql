CREATE TABLE ride_settlements (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    gross_fare bigint NOT NULL,
    commission_bps integer,
    commission_amount bigint NOT NULL DEFAULT 0,
    driver_payout_amount bigint NOT NULL DEFAULT 0,
    payment_status text NOT NULL DEFAULT 'unpaid',
    cash_received_at timestamptz,
    settled_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ride_settlements_money_check CHECK (
        gross_fare >= 0
        AND commission_amount >= 0
        AND driver_payout_amount >= 0
    )
);

CREATE UNIQUE INDEX ridesettlement_ride_id
    ON ride_settlements (ride_id);

CREATE INDEX ridesettlement_payment_status_updated_at
    ON ride_settlements (payment_status, updated_at);
