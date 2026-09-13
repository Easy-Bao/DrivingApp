ALTER TABLE ride_settlements
    ALTER COLUMN commission_bps TYPE bigint
    USING commission_bps::bigint;

ALTER TABLE rides
    ALTER COLUMN commission_bps TYPE bigint
    USING commission_bps::bigint;
