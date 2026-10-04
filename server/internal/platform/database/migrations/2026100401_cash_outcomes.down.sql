ALTER TABLE ride_settlements
    DROP CONSTRAINT IF EXISTS ride_settlements_cash_amounts_check,
    DROP CONSTRAINT IF EXISTS ride_settlements_cash_outcome_check,
    DROP COLUMN IF EXISTS cash_outcome,
    DROP COLUMN IF EXISTS cash_change_amount,
    DROP COLUMN IF EXISTS cash_received_amount;

ALTER TABLE rides
    DROP CONSTRAINT IF EXISTS rides_cash_amounts_check,
    DROP CONSTRAINT IF EXISTS rides_cash_outcome_check,
    DROP COLUMN IF EXISTS cash_outcome,
    DROP COLUMN IF EXISTS cash_change_amount,
    DROP COLUMN IF EXISTS cash_received_amount;
