ALTER TABLE rides
    ADD COLUMN payment_status text NOT NULL DEFAULT 'unpaid',
    ADD COLUMN cash_received_at timestamptz,
    ADD COLUMN cash_received_amount bigint NOT NULL DEFAULT 0,
    ADD COLUMN cash_change_amount bigint NOT NULL DEFAULT 0,
    ADD COLUMN cash_outcome text NOT NULL DEFAULT 'unpaid',
    ADD COLUMN commission_bps integer,
    ADD COLUMN commission_amount bigint NOT NULL DEFAULT 0,
    ADD COLUMN driver_payout_amount bigint NOT NULL DEFAULT 0;

UPDATE rides AS ride
SET payment_status = settlement.payment_status,
    cash_received_at = settlement.cash_received_at,
    cash_received_amount = settlement.cash_received_amount,
    cash_change_amount = settlement.cash_change_amount,
    cash_outcome = settlement.cash_outcome,
    commission_bps = settlement.commission_bps,
    commission_amount = settlement.commission_amount,
    driver_payout_amount = settlement.driver_payout_amount
FROM ride_settlements AS settlement
WHERE settlement.ride_id = ride.id;

ALTER TABLE rides
    DROP CONSTRAINT IF EXISTS rides_money_check,
    ADD CONSTRAINT rides_payment_status_check CHECK (
        payment_status IN ('unpaid', 'paid')
    ),
    ADD CONSTRAINT rides_cash_amounts_check CHECK (
        cash_received_amount >= 0
        AND cash_change_amount >= 0
        AND cash_change_amount <= cash_received_amount
    ),
    ADD CONSTRAINT rides_cash_outcome_check CHECK (
        cash_outcome IN ('paid', 'partial', 'refused', 'unpaid', 'disputed')
    ),
    ADD CONSTRAINT rides_money_check CHECK (
        fare_amount >= 0
        AND cash_received_amount >= 0
        AND cash_change_amount >= 0
        AND cash_change_amount <= cash_received_amount
        AND cancellation_details IS NOT NULL
        AND commission_amount >= 0
        AND driver_payout_amount >= 0
    );
