ALTER TABLE rides
    ALTER COLUMN commission_bps TYPE integer
    USING commission_bps::integer;

ALTER TABLE ride_settlements
    ALTER COLUMN commission_bps TYPE integer
    USING commission_bps::integer;
