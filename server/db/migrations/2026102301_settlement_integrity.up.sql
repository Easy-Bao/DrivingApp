-- Preserve historical rows without silently rewriting financial records.
-- New inserts and updates are checked; validate existing rows after explicit reconciliation.
ALTER TABLE ride_settlements
    ADD CONSTRAINT ride_settlements_commission_range_check CHECK (
        commission_bps BETWEEN 0 AND 10000
    ) NOT VALID,
    ADD CONSTRAINT ride_settlements_payment_outcome_check CHECK (
        (payment_status = 'paid') = (cash_outcome = 'paid')
    ) NOT VALID,
    ADD CONSTRAINT ride_settlements_cash_collection_check CHECK (
        CASE cash_outcome
            WHEN 'paid' THEN gross_fare > 0
                AND cash_received_amount - cash_change_amount = gross_fare
            WHEN 'partial' THEN cash_change_amount = 0
                AND cash_received_amount > 0 AND cash_received_amount < gross_fare
            WHEN 'unpaid' THEN cash_received_amount = cash_change_amount
            WHEN 'refused' THEN cash_received_amount = cash_change_amount
            ELSE true
        END
    ) NOT VALID;
