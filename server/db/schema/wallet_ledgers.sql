CREATE TABLE wallet_ledgers (
    id serial PRIMARY KEY,
    driver_id integer NOT NULL,
    ride_id integer NOT NULL,
    amount_centavos bigint NOT NULL,
    commission_centavos bigint NOT NULL,
    kind text NOT NULL DEFAULT 'cash_trip',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX walletledger_ride_id
    ON wallet_ledgers (ride_id);

CREATE INDEX wallet_ledger_driver_created_idx
    ON wallet_ledgers (driver_id, created_at);
