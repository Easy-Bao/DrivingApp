ALTER TABLE wallet_ledgers
    RENAME COLUMN commission_amount TO commission_centavos;

ALTER TABLE wallet_ledgers
    RENAME COLUMN amount TO amount_centavos;

ALTER TABLE driver_wallet_accounts
    RENAME COLUMN balance TO balance_centavos;

ALTER TABLE ride_settlements
    RENAME COLUMN driver_payout_amount TO driver_payout_centavos;

ALTER TABLE ride_settlements
    RENAME COLUMN commission_amount TO commission_centavos;

ALTER TABLE ride_settlements
    RENAME COLUMN gross_fare TO gross_fare_centavos;

ALTER TABLE bid_offers
    RENAME COLUMN proposed_fare TO proposed_fare_centavos;

ALTER TABLE bid_sessions
    RENAME COLUMN offered_fare TO offered_fare_centavos;

ALTER TABLE rides
    RENAME COLUMN driver_payout_amount TO driver_payout_centavos;

ALTER TABLE rides
    RENAME COLUMN commission_amount TO commission_centavos;

ALTER TABLE rides
    RENAME COLUMN fare_amount TO fare_centavos;
