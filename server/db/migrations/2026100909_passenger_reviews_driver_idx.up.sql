CREATE INDEX CONCURRENTLY IF NOT EXISTS passengerreview_driver_id_idx
    ON passenger_reviews (driver_id);
