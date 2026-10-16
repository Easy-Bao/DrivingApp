-- name: CreateUser :one
INSERT INTO users (name, phone, email, password_hash, role, is_verified)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING id, name, phone, email, password_hash, role, is_verified,
    account_status, created_at, updated_at;

-- name: MarkUserVerified :execrows
UPDATE users
SET is_verified = true,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1;

-- name: UpdateUserPassword :execrows
UPDATE users
SET password_hash = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1;

-- name: CreateDriverProfile :exec
INSERT INTO driver_profiles (user_id, name, vehicle_type, plate_number)
VALUES ($1, $2, $3, $4);

-- name: CreatePassengerProfile :exec
INSERT INTO passenger_profiles (user_id, name, preferred_ride_type)
VALUES ($1, $2, $3);

-- name: GetDriverProfileByUserID :one
SELECT name, vehicle_type, plate_number
FROM driver_profiles
WHERE user_id = $1
LIMIT 1;

-- name: GetPassengerProfileByUserID :one
SELECT name, preferred_ride_type
FROM passenger_profiles
WHERE user_id = $1
LIMIT 1;
