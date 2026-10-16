CREATE INDEX CONCURRENTLY IF NOT EXISTS review_passenger_id_idx
    ON reviews (passenger_id);
