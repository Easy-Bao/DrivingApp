DROP INDEX IF EXISTS rides_one_active_ride_per_driver_idx;

CREATE INDEX rides_active_driver_idx
    ON rides (driver_id)
    WHERE driver_id IS NOT NULL
      AND status IN ('assigned', 'accepted', 'arrived', 'in_transit');
