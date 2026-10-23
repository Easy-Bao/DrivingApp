ALTER TABLE ride_settlements
    DROP CONSTRAINT ride_settlements_commission_range_check,
    DROP CONSTRAINT ride_settlements_payment_outcome_check,
    DROP CONSTRAINT ride_settlements_cash_collection_check;
