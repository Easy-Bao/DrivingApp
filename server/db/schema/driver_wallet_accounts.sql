CREATE TABLE driver_wallet_accounts (
    id serial PRIMARY KEY,
    driver_id integer NOT NULL,
    balance_centavos bigint NOT NULL DEFAULT 0,
    version bigint NOT NULL DEFAULT 0,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX driverwalletaccount_driver_id
    ON driver_wallet_accounts (driver_id);
