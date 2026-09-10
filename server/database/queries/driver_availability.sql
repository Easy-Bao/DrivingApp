-- name: ListOnlineDrivers :many
SELECT
    profile.id,
    profile.user_id,
    profile.name,
    profile.vehicle_type,
    profile.plate_number,
    COALESCE((
        SELECT AVG(review.rating)
        FROM reviews AS review
        WHERE review.driver_id = profile.user_id
    ), profile.rating)::double precision AS rating,
    COUNT(ride.id) FILTER (
        WHERE ride.status IN ('assigned', 'accepted', 'arrived', 'in_transit')
    )::bigint AS onboard_passenger_count
FROM driver_profiles AS profile
LEFT JOIN rides AS ride ON ride.driver_id = profile.user_id
WHERE profile.is_online = true
  AND profile.user_id = ANY(sqlc.arg('driver_ids')::int[])
GROUP BY profile.id, profile.user_id, profile.name, profile.vehicle_type, profile.plate_number, profile.rating
ORDER BY profile.id
LIMIT sqlc.arg('limit')::int;

-- name: ListPublicDriverSummaries :many
SELECT
    profile.user_id AS id,
    profile.name,
    profile.vehicle_type,
    COALESCE((
        SELECT AVG(review.rating)
        FROM reviews AS review
        WHERE review.driver_id = profile.user_id
    ), profile.rating)::double precision AS rating
FROM driver_profiles AS profile
WHERE profile.is_online = true
ORDER BY profile.id
LIMIT sqlc.arg('limit')::int;
