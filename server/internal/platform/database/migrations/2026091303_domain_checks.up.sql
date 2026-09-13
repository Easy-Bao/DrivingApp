DO $migration$
BEGIN
    IF EXISTS (SELECT 1 FROM driver_profiles WHERE rating < 0 OR rating > 5)
       OR EXISTS (SELECT 1 FROM reviews WHERE rating < 0 OR rating > 5)
       OR EXISTS (SELECT 1 FROM passenger_reviews WHERE rating < 0 OR rating > 5)
       OR EXISTS (
           SELECT 1
           FROM rides
           WHERE fare_centavos < 0
              OR commission_centavos < 0
              OR driver_payout_centavos < 0
              OR (distance_km IS NOT NULL AND distance_km < 0)
              OR (duration_minutes IS NOT NULL AND duration_minutes < 0)
              OR (pickup_latitude IS NOT NULL AND (pickup_latitude < -90 OR pickup_latitude > 90))
              OR (pickup_longitude IS NOT NULL AND (pickup_longitude < -180 OR pickup_longitude > 180))
              OR (dropoff_latitude IS NOT NULL AND (dropoff_latitude < -90 OR dropoff_latitude > 90))
              OR (dropoff_longitude IS NOT NULL AND (dropoff_longitude < -180 OR dropoff_longitude > 180))
       )
       OR EXISTS (
           SELECT 1
           FROM bid_sessions
           WHERE offered_fare_centavos < 0
              OR distance_km < 0
              OR duration_minutes < 0
              OR pickup_latitude < -90 OR pickup_latitude > 90
              OR pickup_longitude < -180 OR pickup_longitude > 180
              OR dropoff_latitude < -90 OR dropoff_latitude > 90
              OR dropoff_longitude < -180 OR dropoff_longitude > 180
       )
       OR EXISTS (SELECT 1 FROM bid_offers WHERE proposed_fare_centavos < 0)
       OR EXISTS (SELECT 1 FROM bids WHERE offered_fare_centavos < 0)
       OR EXISTS (
           SELECT 1
           FROM ride_settlements
           WHERE gross_fare_centavos < 0
              OR commission_centavos < 0
              OR driver_payout_centavos < 0
       ) THEN
        RAISE EXCEPTION 'domain check migration found invalid existing data';
    END IF;
END
$migration$;

ALTER TABLE driver_profiles
    ADD CONSTRAINT driver_profiles_rating_check CHECK (rating BETWEEN 0 AND 5);

ALTER TABLE reviews
    ADD CONSTRAINT reviews_rating_check CHECK (rating BETWEEN 0 AND 5);

ALTER TABLE passenger_reviews
    ADD CONSTRAINT passenger_reviews_rating_check CHECK (rating BETWEEN 0 AND 5);

ALTER TABLE rides
    ADD CONSTRAINT rides_money_check CHECK (
        fare_centavos >= 0
        AND commission_centavos >= 0
        AND driver_payout_centavos >= 0
    ),
    ADD CONSTRAINT rides_route_metrics_check CHECK (
        (distance_km IS NULL OR distance_km >= 0)
        AND (duration_minutes IS NULL OR duration_minutes >= 0)
    ),
    ADD CONSTRAINT rides_coordinates_check CHECK (
        (pickup_latitude IS NULL OR pickup_latitude BETWEEN -90 AND 90)
        AND (pickup_longitude IS NULL OR pickup_longitude BETWEEN -180 AND 180)
        AND (dropoff_latitude IS NULL OR dropoff_latitude BETWEEN -90 AND 90)
        AND (dropoff_longitude IS NULL OR dropoff_longitude BETWEEN -180 AND 180)
    );

ALTER TABLE bid_sessions
    ADD CONSTRAINT bid_sessions_offer_check CHECK (offered_fare_centavos >= 0),
    ADD CONSTRAINT bid_sessions_route_metrics_check CHECK (distance_km >= 0 AND duration_minutes >= 0),
    ADD CONSTRAINT bid_sessions_coordinates_check CHECK (
        pickup_latitude BETWEEN -90 AND 90
        AND pickup_longitude BETWEEN -180 AND 180
        AND dropoff_latitude BETWEEN -90 AND 90
        AND dropoff_longitude BETWEEN -180 AND 180
    );

ALTER TABLE bid_offers
    ADD CONSTRAINT bid_offers_fare_check CHECK (proposed_fare_centavos >= 0);

ALTER TABLE bids
    ADD CONSTRAINT bids_fare_check CHECK (offered_fare_centavos >= 0);

ALTER TABLE ride_settlements
    ADD CONSTRAINT ride_settlements_money_check CHECK (
        gross_fare_centavos >= 0
        AND commission_centavos >= 0
        AND driver_payout_centavos >= 0
    );
