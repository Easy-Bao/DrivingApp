-- name: GetDriverProfileByUserIDFull :one
SELECT id, user_id, name, vehicle_type, plate_number, rating, is_online,
    online_last_seen_at
FROM driver_profiles
WHERE user_id = $1
LIMIT 1;

-- name: GetPassengerProfileByUserIDFull :one
SELECT id, user_id, name, address, gender, avatar_storage_key,
    avatar_content_type, preferred_ride_type
FROM passenger_profiles
WHERE user_id = $1
LIMIT 1;

-- name: UpdateUserProfile :one
UPDATE users
SET name = $2, phone = $3, email = $4
WHERE id = $1
RETURNING id, name, phone, email, password_hash, role, is_verified,
    account_status;

-- name: UpdateDriverProfile :one
UPDATE driver_profiles
SET name = $2,
    vehicle_type = $3,
    plate_number = $4,
    is_online = $5,
    online_last_seen_at = CASE WHEN $5::boolean THEN online_last_seen_at ELSE NULL END
WHERE id = $1
RETURNING id, user_id, name, vehicle_type, plate_number, rating, is_online,
    online_last_seen_at;

-- name: UpdateDriverOnlineStatus :one
UPDATE driver_profiles
SET is_online = sqlc.arg('is_online'),
    online_last_seen_at = CASE
        WHEN sqlc.arg('is_online')::boolean THEN CURRENT_TIMESTAMP
        ELSE NULL
    END
FROM users AS account
WHERE driver_profiles.user_id = sqlc.arg('user_id')
  AND (
      driver_profiles.user_id = sqlc.arg('target_id')
      OR driver_profiles.id = sqlc.arg('target_id')
  )
  AND account.id = driver_profiles.user_id
  AND (
      sqlc.arg('is_online')::boolean = false
      OR (
          account.account_status = 'active'
          AND account.is_verified = true
      )
  )
RETURNING driver_profiles.id, driver_profiles.user_id, driver_profiles.name,
    driver_profiles.vehicle_type, driver_profiles.plate_number,
    driver_profiles.rating, driver_profiles.is_online,
    driver_profiles.online_last_seen_at;

-- name: UpdatePassengerProfile :one
UPDATE passenger_profiles
SET name = $2, address = $3, gender = $4, preferred_ride_type = $5
WHERE id = $1
RETURNING id, user_id, name, address, gender, avatar_storage_key,
    avatar_content_type, preferred_ride_type;

-- name: UpdatePassengerAvatar :execrows
UPDATE passenger_profiles
SET avatar_storage_key = $2, avatar_content_type = $3
WHERE id = $1;

-- name: ListNotifications :many
SELECT id, user_id, type, title, body, is_read, created_at
FROM notifications
WHERE user_id = $1
ORDER BY id DESC
LIMIT $2 OFFSET $3;

-- name: DeleteNotification :execrows
DELETE FROM notifications
WHERE id = $1 AND user_id = $2;
