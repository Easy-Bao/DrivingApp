CREATE TABLE wallet_ledgers (
    id serial PRIMARY KEY,
    driver_id integer NOT NULL,
    ride_id integer NOT NULL,
    amount bigint NOT NULL,
    commission_amount bigint NOT NULL,
    kind text NOT NULL DEFAULT 'cash_trip',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT wallet_ledgers_driver_fk
        FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT wallet_ledgers_ride_fk
        FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX walletledger_ride_id
    ON wallet_ledgers (ride_id);

CREATE INDEX wallet_ledger_driver_created_idx
    ON wallet_ledgers (driver_id, created_at);
