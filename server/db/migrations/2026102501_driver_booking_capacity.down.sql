DO $migration$
BEGIN
    IF EXISTS (
        SELECT driver_id
        FROM rides
        WHERE driver_id IS NOT NULL
          AND status IN ('assigned', 'accepted', 'arrived', 'in_transit')
        GROUP BY driver_id
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'cannot restore one-booking capacity while drivers have multiple active bookings';
    END IF;
END
$migration$;

CREATE UNIQUE INDEX rides_one_active_ride_per_driver_idx
    ON rides (driver_id)
    WHERE driver_id IS NOT NULL
      AND status IN ('assigned', 'accepted', 'arrived', 'in_transit');

DROP INDEX IF EXISTS rides_active_driver_idx;
