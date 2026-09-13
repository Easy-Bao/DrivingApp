ALTER TABLE ride_settlements
    DROP CONSTRAINT IF EXISTS ride_settlements_money_check;

ALTER TABLE bids
    DROP CONSTRAINT IF EXISTS bids_fare_check;

ALTER TABLE bid_offers
    DROP CONSTRAINT IF EXISTS bid_offers_fare_check;

ALTER TABLE bid_sessions
    DROP CONSTRAINT IF EXISTS bid_sessions_coordinates_check,
    DROP CONSTRAINT IF EXISTS bid_sessions_route_metrics_check,
    DROP CONSTRAINT IF EXISTS bid_sessions_offer_check;

ALTER TABLE rides
    DROP CONSTRAINT IF EXISTS rides_coordinates_check,
    DROP CONSTRAINT IF EXISTS rides_route_metrics_check,
    DROP CONSTRAINT IF EXISTS rides_money_check;

ALTER TABLE passenger_reviews
    DROP CONSTRAINT IF EXISTS passenger_reviews_rating_check;

ALTER TABLE reviews
    DROP CONSTRAINT IF EXISTS reviews_rating_check;

ALTER TABLE driver_profiles
    DROP CONSTRAINT IF EXISTS driver_profiles_rating_check;
