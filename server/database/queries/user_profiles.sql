-- name: GetDriverProfileByUserIDFull :one
SELECT id, user_id, name, vehicle_type, plate_number, rating, is_online,
    wallet_balance_centavos
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
RETURNING id, name, phone, email, password_hash, role, is_verified;

-- name: UpdateDriverProfile :one
UPDATE driver_profiles
SET name = $2, vehicle_type = $3, plate_number = $4, is_online = $5
WHERE id = $1
RETURNING id, user_id, name, vehicle_type, plate_number, rating, is_online,
    wallet_balance_centavos;

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
