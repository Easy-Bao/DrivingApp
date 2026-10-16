INSERT INTO ride_settlements (
    ride_id,
    gross_fare,
    commission_bps,
    commission_amount,
    driver_payout_amount,
    payment_status,
    cash_received_at,
    cash_received_amount,
    cash_change_amount,
    cash_outcome,
    settled_at
)
SELECT
    rides.id,
    rides.fare_amount,
    rides.commission_bps,
    rides.commission_amount,
    rides.driver_payout_amount,
    rides.payment_status,
    rides.cash_received_at,
    rides.cash_received_amount,
    rides.cash_change_amount,
    rides.cash_outcome,
    CASE WHEN rides.payment_status = 'paid' THEN rides.cash_received_at END
FROM rides
WHERE rides.status <> 'requested'
   OR rides.payment_status <> 'unpaid'
   OR rides.cash_received_at IS NOT NULL
   OR rides.cash_received_amount <> 0
   OR rides.cash_change_amount <> 0
   OR rides.cash_outcome <> 'unpaid'
   OR rides.commission_bps IS NOT NULL
   OR rides.commission_amount <> 0
   OR rides.driver_payout_amount <> 0
ON CONFLICT (ride_id) DO NOTHING;

ALTER TABLE rides
    DROP CONSTRAINT IF EXISTS rides_payment_status_check,
    DROP CONSTRAINT IF EXISTS rides_cash_amounts_check,
    DROP CONSTRAINT IF EXISTS rides_cash_outcome_check,
    DROP CONSTRAINT IF EXISTS rides_money_check;

ALTER TABLE rides
    ADD CONSTRAINT rides_money_check CHECK (
        fare_amount >= 0
        AND cancellation_details IS NOT NULL
    );

ALTER TABLE rides
    DROP COLUMN payment_status,
    DROP COLUMN cash_received_at,
    DROP COLUMN cash_received_amount,
    DROP COLUMN cash_change_amount,
    DROP COLUMN cash_outcome,
    DROP COLUMN commission_bps,
    DROP COLUMN commission_amount,
    DROP COLUMN driver_payout_amount;
