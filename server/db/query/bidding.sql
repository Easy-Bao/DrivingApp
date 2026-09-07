-- name: LockUserForBidSession :one
SELECT id
FROM users
WHERE id = $1
FOR UPDATE;

-- name: ExpireBidSessions :exec
UPDATE bid_sessions
SET status = 'expired'
WHERE passenger_id = $1
  AND status = 'open'
  AND expires_at <= $2;

-- name: HasActiveBidSession :one
SELECT EXISTS (
    SELECT 1
    FROM bid_sessions
    WHERE passenger_id = $1
      AND status = 'open'
      AND expires_at > $2
);

-- name: HasActivePassengerRide :one
SELECT EXISTS (
    SELECT 1
    FROM rides
    WHERE passenger_id = $1
      AND status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit')
);

-- name: CreateBidSession :one
INSERT INTO bid_sessions (
    passenger_id, ride_type, pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name, passenger_note,
    distance_km, duration_minutes, offered_fare_centavos, status,
    target_driver_id, expires_at, created_at
)
VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
    COALESCE(sqlc.narg('created_at')::timestamptz, CURRENT_TIMESTAMP)
)
RETURNING id, passenger_id, ride_type, pickup_latitude, pickup_longitude,
    pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name,
    passenger_note, distance_km, duration_minutes, offered_fare_centavos,
    status, target_driver_id, accepted_driver_id, expires_at, created_at;

-- name: GetOnlineDriverProfileForBidding :one
SELECT id, user_id, name, vehicle_type, plate_number, rating, is_online,
    wallet_balance_centavos
FROM driver_profiles
WHERE user_id = $1
  AND is_online = true
LIMIT 1;

-- name: LockOnlineDriverProfileForBidding :one
SELECT id, user_id, name, vehicle_type, plate_number, rating, is_online,
    wallet_balance_centavos
FROM driver_profiles
WHERE user_id = $1
  AND is_online = true
LIMIT 1
FOR UPDATE;

-- name: CountActiveRidesForDriver :one
SELECT count(*)
FROM rides
WHERE driver_id = $1
  AND status IN ('assigned', 'accepted', 'arrived', 'in_transit');

-- name: ListActiveBidSessions :many
SELECT sessions.id, sessions.passenger_id, sessions.ride_type,
    sessions.pickup_latitude, sessions.pickup_longitude, sessions.pickup_name,
    sessions.dropoff_latitude, sessions.dropoff_longitude, sessions.dropoff_name,
    sessions.passenger_note, sessions.distance_km, sessions.duration_minutes,
    sessions.offered_fare_centavos, sessions.status, sessions.target_driver_id,
    sessions.accepted_driver_id, sessions.expires_at, sessions.created_at
FROM bid_sessions AS sessions
WHERE sessions.status = 'open'
  AND sessions.expires_at > $1
ORDER BY sessions.created_at
LIMIT 50;

-- name: ListTargetedActiveBidSessions :many
SELECT sessions.id, sessions.passenger_id, sessions.ride_type,
    sessions.pickup_latitude, sessions.pickup_longitude, sessions.pickup_name,
    sessions.dropoff_latitude, sessions.dropoff_longitude, sessions.dropoff_name,
    sessions.passenger_note, sessions.distance_km, sessions.duration_minutes,
    sessions.offered_fare_centavos, sessions.status, sessions.target_driver_id,
    sessions.accepted_driver_id, sessions.expires_at, sessions.created_at
FROM bid_sessions AS sessions
WHERE sessions.status = 'open'
  AND sessions.expires_at > $1
  AND (sessions.target_driver_id IS NULL OR sessions.target_driver_id = $2)
  AND NOT EXISTS (
      SELECT 1
      FROM bid_offers AS offers
      WHERE offers.session_id = sessions.id
        AND offers.driver_id = $2
        AND offers.status = 'pending'
  )
ORDER BY sessions.created_at
LIMIT 50;

-- name: GetBidSessionByID :one
SELECT id, passenger_id, ride_type, pickup_latitude, pickup_longitude,
    pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name,
    passenger_note, distance_km, duration_minutes, offered_fare_centavos,
    status, target_driver_id, accepted_driver_id, expires_at, created_at
FROM bid_sessions
WHERE id = $1
LIMIT 1;

-- name: LockActiveBidSessionForOffer :one
SELECT id, passenger_id, ride_type, pickup_latitude, pickup_longitude,
    pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name,
    passenger_note, distance_km, duration_minutes, offered_fare_centavos,
    status, target_driver_id, accepted_driver_id, expires_at, created_at
FROM bid_sessions
WHERE id = $1
  AND status = 'open'
  AND expires_at > $2
LIMIT 1
FOR UPDATE;

-- name: ListBidOffersBySession :many
SELECT id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare_centavos, status, created_at
FROM bid_offers
WHERE session_id = $1
ORDER BY created_at;

-- name: HasPendingBidOffer :one
SELECT EXISTS (
    SELECT 1
    FROM bid_offers
    WHERE session_id = $1
      AND driver_id = $2
      AND status = 'pending'
);

-- name: CreateBidOffer :one
INSERT INTO bid_offers (
    session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare_centavos, status
)
VALUES ($1, $2, $3, $4, $5, $6, 'pending')
RETURNING id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare_centavos, status, created_at;

-- name: CancelBidSession :one
UPDATE bid_sessions
SET status = 'cancelled'
WHERE id = $1
  AND passenger_id = $2
  AND status = 'open'
RETURNING id, passenger_id, ride_type, pickup_latitude, pickup_longitude,
    pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name,
    passenger_note, distance_km, duration_minutes, offered_fare_centavos,
    status, target_driver_id, accepted_driver_id, expires_at, created_at;

-- name: GetPendingBidOffer :one
SELECT id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare_centavos, status, created_at
FROM bid_offers
WHERE session_id = $1
  AND driver_id = $2
  AND status = 'pending'
LIMIT 1;

-- name: RejectBidOffer :one
UPDATE bid_offers
SET status = 'rejected'
WHERE id = $1
  AND status = 'pending'
RETURNING id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare_centavos, status, created_at;
