ALTER TABLE public.bid_sessions
    ADD CONSTRAINT bid_sessions_pickup_dropoff_different_check
    CHECK (
        (pickup_latitude IS DISTINCT FROM dropoff_latitude)
        OR (pickup_longitude IS DISTINCT FROM dropoff_longitude)
    );
