ALTER TABLE rides
    RENAME COLUMN fare_centavos TO fare_amount;

ALTER TABLE rides
    RENAME COLUMN commission_centavos TO commission_amount;

ALTER TABLE rides
    RENAME COLUMN driver_payout_centavos TO driver_payout_amount;

ALTER TABLE bid_sessions
    RENAME COLUMN offered_fare_centavos TO offered_fare;

ALTER TABLE bid_offers
    RENAME COLUMN proposed_fare_centavos TO proposed_fare;

ALTER TABLE ride_settlements
    RENAME COLUMN gross_fare_centavos TO gross_fare;

ALTER TABLE ride_settlements
    RENAME COLUMN commission_centavos TO commission_amount;

ALTER TABLE ride_settlements
    RENAME COLUMN driver_payout_centavos TO driver_payout_amount;

ALTER TABLE driver_wallet_accounts
    RENAME COLUMN balance_centavos TO balance;

ALTER TABLE wallet_ledgers
    RENAME COLUMN amount_centavos TO amount;

ALTER TABLE wallet_ledgers
    RENAME COLUMN commission_centavos TO commission_amount;
