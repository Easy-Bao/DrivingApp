DO $migration$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM rides
        WHERE pickup_latitude IS NOT NULL
          AND pickup_longitude IS NOT NULL
          AND dropoff_latitude IS NOT NULL
          AND dropoff_longitude IS NOT NULL
          AND pickup_latitude = dropoff_latitude
          AND pickup_longitude = dropoff_longitude
    ) THEN
        RAISE EXCEPTION 'ride route constraint found identical pickup and dropoff coordinates';
    END IF;
END
$migration$;

ALTER TABLE rides
    ADD CONSTRAINT rides_pickup_dropoff_different_check CHECK (
        pickup_latitude IS NULL
        OR pickup_longitude IS NULL
        OR dropoff_latitude IS NULL
        OR dropoff_longitude IS NULL
        OR pickup_latitude <> dropoff_latitude
        OR pickup_longitude <> dropoff_longitude
    );
