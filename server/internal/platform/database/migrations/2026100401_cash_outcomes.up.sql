ALTER TABLE rides
    ADD COLUMN IF NOT EXISTS cash_received_amount bigint NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cash_change_amount bigint NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cash_outcome text NOT NULL DEFAULT 'unpaid';

ALTER TABLE ride_settlements
    ADD COLUMN IF NOT EXISTS cash_received_amount bigint NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cash_change_amount bigint NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cash_outcome text NOT NULL DEFAULT 'unpaid';

UPDATE rides
SET cash_outcome = CASE WHEN payment_status = 'paid' THEN 'paid' ELSE 'unpaid' END,
    cash_received_amount = CASE WHEN payment_status = 'paid' THEN fare_amount ELSE 0 END
WHERE cash_outcome = 'unpaid'
  AND (payment_status = 'paid' OR cash_received_amount = 0);

UPDATE ride_settlements
SET cash_outcome = CASE WHEN payment_status = 'paid' THEN 'paid' ELSE 'unpaid' END,
    cash_received_amount = CASE WHEN payment_status = 'paid' THEN gross_fare ELSE 0 END
WHERE cash_outcome = 'unpaid'
  AND (payment_status = 'paid' OR cash_received_amount = 0);

ALTER TABLE rides
    ADD CONSTRAINT rides_cash_outcome_check CHECK (
        cash_outcome IN ('paid', 'partial', 'refused', 'unpaid', 'disputed')
    ),
    ADD CONSTRAINT rides_cash_amounts_check CHECK (
        cash_received_amount >= 0
        AND cash_change_amount >= 0
        AND cash_change_amount <= cash_received_amount
    );

ALTER TABLE ride_settlements
    ADD CONSTRAINT ride_settlements_cash_outcome_check CHECK (
        cash_outcome IN ('paid', 'partial', 'refused', 'unpaid', 'disputed')
    ),
    ADD CONSTRAINT ride_settlements_cash_amounts_check CHECK (
        cash_received_amount >= 0
        AND cash_change_amount >= 0
        AND cash_change_amount <= cash_received_amount
    );
