-- name: ListOnlineDrivers :many
WITH eligible_profiles AS (
    SELECT
        profile.id,
        profile.user_id,
        profile.name,
        profile.vehicle_type,
        profile.plate_number,
        profile.rating
    FROM driver_profiles AS profile
    JOIN users AS account ON account.id = profile.user_id
    WHERE account.account_status = 'active'
      AND account.is_verified = true
      AND profile.is_online = true
      AND profile.online_last_seen_at >= sqlc.arg('online_cutoff')::timestamptz
      AND profile.user_id = ANY(sqlc.arg('driver_ids')::int[])
    ORDER BY profile.id
    LIMIT sqlc.arg('limit')::int
), review_ratings AS (
    SELECT review.driver_id, AVG(review.rating) AS rating
    FROM reviews AS review
    JOIN eligible_profiles AS profile ON profile.user_id = review.driver_id
    GROUP BY review.driver_id
), onboard_counts AS (
    SELECT
        ride.driver_id,
        COUNT(*) FILTER (
            WHERE ride.status IN ('assigned', 'accepted', 'arrived', 'in_transit')
        )::bigint AS onboard_passenger_count
    FROM rides AS ride
    JOIN eligible_profiles AS profile ON profile.user_id = ride.driver_id
    GROUP BY ride.driver_id
)
SELECT
    profile.id,
    profile.user_id,
    profile.name,
    profile.vehicle_type,
    profile.plate_number,
    COALESCE(review_ratings.rating, profile.rating)::double precision AS rating,
    COALESCE(onboard_counts.onboard_passenger_count, 0)::bigint AS onboard_passenger_count
FROM eligible_profiles AS profile
LEFT JOIN review_ratings ON review_ratings.driver_id = profile.user_id
LEFT JOIN onboard_counts ON onboard_counts.driver_id = profile.user_id
ORDER BY profile.id;

-- name: ListPublicDriverSummaries :many
WITH eligible_profiles AS (
    SELECT
        profile.id,
        profile.user_id,
        profile.name,
        profile.vehicle_type,
        profile.rating
    FROM driver_profiles AS profile
    JOIN users AS account ON account.id = profile.user_id
    WHERE account.account_status = 'active'
      AND account.is_verified = true
      AND profile.is_online = true
      AND profile.online_last_seen_at >= sqlc.arg('online_cutoff')::timestamptz
    ORDER BY profile.id
    LIMIT sqlc.arg('limit')::int
), review_ratings AS (
    SELECT review.driver_id, AVG(review.rating) AS rating
    FROM reviews AS review
    JOIN eligible_profiles AS profile ON profile.user_id = review.driver_id
    GROUP BY review.driver_id
)
SELECT
    profile.user_id AS id,
    profile.name,
    profile.vehicle_type,
    COALESCE(review_ratings.rating, profile.rating)::double precision AS rating
FROM eligible_profiles AS profile
LEFT JOIN review_ratings ON review_ratings.driver_id = profile.user_id
ORDER BY profile.id;
