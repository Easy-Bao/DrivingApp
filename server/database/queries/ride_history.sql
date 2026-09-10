-- name: ListDriverRides :many
SELECT sqlc.embed(r),
    COALESCE(NULLIF(passenger_profile.name, ''), user_account.name, '') AS passenger_name,
    COALESCE(user_account.phone, '') AS passenger_phone,
    passenger_review.rating AS passenger_rating,
    passenger_review.comment AS passenger_feedback
FROM rides AS r
LEFT JOIN users AS user_account ON user_account.id = r.passenger_id
LEFT JOIN passenger_profiles AS passenger_profile ON passenger_profile.user_id = r.passenger_id
LEFT JOIN reviews AS passenger_review ON passenger_review.ride_id = r.id
WHERE r.driver_id = sqlc.arg('driver_id')
  AND (
      sqlc.arg('active_only')::boolean = false
      OR r.status IN ('assigned', 'accepted', 'arrived', 'in_transit')
  )
ORDER BY r.created_at DESC, r.id DESC
LIMIT sqlc.arg('limit')::int
OFFSET sqlc.arg('offset')::int;

-- name: ListPassengerRides :many
SELECT sqlc.embed(r),
    COALESCE(driver_profile.name, '') AS driver_profile_name,
    COALESCE(driver_profile.vehicle_type, '') AS driver_profile_vehicle_type,
    COALESCE(driver_profile.plate_number, '') AS driver_profile_plate_number
FROM rides AS r
LEFT JOIN driver_profiles AS driver_profile ON driver_profile.user_id = r.driver_id
WHERE r.passenger_id = sqlc.arg('passenger_id')
ORDER BY r.created_at DESC, r.id DESC
LIMIT sqlc.arg('limit')::int
OFFSET sqlc.arg('offset')::int;

-- name: ListRecentPassengerRides :many
SELECT sqlc.embed(r),
    COALESCE(driver_profile.name, '') AS driver_profile_name,
    COALESCE(driver_profile.vehicle_type, '') AS driver_profile_vehicle_type,
    COALESCE(driver_profile.plate_number, '') AS driver_profile_plate_number
FROM rides AS r
LEFT JOIN driver_profiles AS driver_profile ON driver_profile.user_id = r.driver_id
WHERE r.passenger_id = sqlc.arg('passenger_id')
ORDER BY r.id DESC
LIMIT sqlc.arg('limit')::int;
