CREATE TABLE driver_wallet_accounts (
    id serial PRIMARY KEY,
    driver_id integer NOT NULL,
    balance bigint NOT NULL DEFAULT 0,
    version bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT driver_wallet_accounts_driver_fk
        FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX driverwalletaccount_driver_id
    ON driver_wallet_accounts (driver_id);
