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
        RAISE EXCEPTION 'driver active ride migration found duplicate active rides';
    END IF;
END
$migration$;

CREATE UNIQUE INDEX rides_one_active_ride_per_driver_idx
    ON rides (driver_id)
    WHERE driver_id IS NOT NULL
      AND status IN ('assigned', 'accepted', 'arrived', 'in_transit');
