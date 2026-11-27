CREATE INDEX IF NOT EXISTS ride_passenger_id_created_at
    ON rides (passenger_id, created_at);

CREATE INDEX IF NOT EXISTS ride_driver_id_created_at
    ON rides (driver_id, created_at);

CREATE INDEX IF NOT EXISTS notification_user_id_created_at
    ON notifications (user_id, created_at);
