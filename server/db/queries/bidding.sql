-- name: LockUserForBidSession :one
SELECT id
FROM users
WHERE id = $1
FOR UPDATE;

-- name: ExpireBidSessions :exec
WITH expired AS (
    UPDATE bid_sessions
    SET status = 'expired'
    WHERE passenger_id = $1
      AND status = 'open'
      AND expires_at <= $2
    RETURNING id, passenger_id, booking_reference
), rejected_offers AS (
    UPDATE bid_offers
    SET status = 'rejected'
    WHERE status = 'pending'
      AND session_id IN (SELECT id FROM expired)
)
INSERT INTO notifications (user_id, type, title, body)
SELECT passenger_id, 'ride', 'No nearby driver found',
    'No nearby driver was found for Booking ID - ' || booking_reference ||
    '. Your request has expired. Please try searching again.'
FROM expired;

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
    passenger_id, pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name, passenger_note,
    distance_km, duration_minutes, offered_fare, status,
    target_driver_id, expires_at, created_at
)
VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
    COALESCE(sqlc.narg('created_at')::timestamptz, CURRENT_TIMESTAMP)
)
RETURNING id, booking_reference, passenger_id, ride_type, pickup_latitude, pickup_longitude,
    pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name,
    passenger_note, distance_km, duration_minutes, offered_fare,
    status, target_driver_id, accepted_driver_id, expires_at, created_at;

-- name: GetOnlineDriverProfileForBidding :one
SELECT driver_profiles.id, driver_profiles.user_id, driver_profiles.name,
    driver_profiles.vehicle_type, driver_profiles.plate_number,
    driver_profiles.rating, driver_profiles.is_online,
    driver_profiles.online_last_seen_at
FROM driver_profiles
JOIN users AS account ON account.id = driver_profiles.user_id
WHERE driver_profiles.user_id = $1
  AND account.account_status = 'active'
  AND (
      account.is_verified = true
      OR sqlc.arg('allow_unverified_test_drivers')::boolean
  )
  AND driver_profiles.is_online = true
  AND driver_profiles.online_last_seen_at >= sqlc.arg('online_cutoff')::timestamptz
LIMIT 1;

-- name: LockOnlineDriverProfileForBidding :one
SELECT driver_profiles.id, driver_profiles.user_id, driver_profiles.name,
    driver_profiles.vehicle_type, driver_profiles.plate_number,
    driver_profiles.rating, driver_profiles.is_online,
    driver_profiles.online_last_seen_at
FROM driver_profiles
JOIN users AS account ON account.id = driver_profiles.user_id
WHERE driver_profiles.user_id = $1
  AND account.account_status = 'active'
  AND (
      account.is_verified = true
      OR sqlc.arg('allow_unverified_test_drivers')::boolean
  )
  AND driver_profiles.is_online = true
  AND driver_profiles.online_last_seen_at >= sqlc.arg('online_cutoff')::timestamptz
LIMIT 1
FOR UPDATE;

-- name: CountActiveRidesForDriver :one
SELECT count(*)
FROM rides
WHERE driver_id = $1
  AND status IN ('assigned', 'accepted', 'arrived', 'in_transit');

-- name: HasOverdueCashSettlementForDriver :one
SELECT EXISTS (
    SELECT 1
    FROM rides AS ride
    LEFT JOIN ride_settlements AS settlement ON settlement.ride_id = ride.id
    WHERE ride.driver_id = $1
      AND ride.status = 'completed'
      AND COALESCE(settlement.payment_status, 'unpaid') = 'unpaid'
      AND ride.completed_at IS NOT NULL
      AND ride.completed_at <= $2
);

-- name: ListActiveBidSessions :many
SELECT sessions.id, sessions.booking_reference, sessions.passenger_id, sessions.ride_type,
    sessions.pickup_latitude, sessions.pickup_longitude, sessions.pickup_name,
    sessions.dropoff_latitude, sessions.dropoff_longitude, sessions.dropoff_name,
    sessions.passenger_note, sessions.distance_km, sessions.duration_minutes,
    sessions.offered_fare, sessions.status, sessions.target_driver_id,
    sessions.accepted_driver_id, sessions.expires_at, sessions.created_at
FROM bid_sessions AS sessions
WHERE sessions.status = 'open'
  AND sessions.expires_at > $1
ORDER BY sessions.created_at, sessions.id
LIMIT 50;

-- name: ListTargetedActiveBidSessions :many
SELECT sessions.id, sessions.booking_reference, sessions.passenger_id, sessions.ride_type,
    sessions.pickup_latitude, sessions.pickup_longitude, sessions.pickup_name,
    sessions.dropoff_latitude, sessions.dropoff_longitude, sessions.dropoff_name,
    sessions.passenger_note, sessions.distance_km, sessions.duration_minutes,
    sessions.offered_fare, sessions.status, sessions.target_driver_id,
    sessions.accepted_driver_id, sessions.expires_at, sessions.created_at
FROM bid_sessions AS sessions
WHERE sessions.status = 'open'
  AND sessions.expires_at > $1
  AND (sessions.target_driver_id IS NULL OR sessions.target_driver_id = $2)
ORDER BY EXISTS (
    SELECT 1
    FROM bid_offers AS offers
    WHERE offers.session_id = sessions.id
      AND offers.driver_id = $2
      AND offers.status = 'pending'
) DESC, sessions.created_at, sessions.id
LIMIT 50;

-- name: ListPendingBidOffersForDriver :many
SELECT offers.id, offers.session_id, offers.driver_id, offers.driver_name,
    offers.plate_number, offers.vehicle_type, offers.proposed_fare,
    offers.status, offers.created_at
FROM bid_offers AS offers
JOIN bid_sessions AS sessions ON sessions.id = offers.session_id
WHERE offers.driver_id = $1
  AND offers.status = 'pending'
  AND sessions.status = 'open'
  AND sessions.expires_at > $2
  AND (sessions.target_driver_id IS NULL OR sessions.target_driver_id = $1)
  AND offers.session_id = ANY(sqlc.arg('session_ids')::int[])
ORDER BY sessions.created_at, sessions.id;

-- name: GetBidSessionByID :one
SELECT id, booking_reference, passenger_id, ride_type, pickup_latitude, pickup_longitude,
    pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name,
    passenger_note, distance_km, duration_minutes, offered_fare,
    status, target_driver_id, accepted_driver_id, expires_at, created_at
FROM bid_sessions
WHERE id = $1
LIMIT 1;

-- name: LockActiveBidSessionForOffer :one
SELECT id, booking_reference, passenger_id, ride_type, pickup_latitude, pickup_longitude,
    pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name,
    passenger_note, distance_km, duration_minutes, offered_fare,
    status, target_driver_id, accepted_driver_id, expires_at, created_at
FROM bid_sessions
WHERE id = $1
  AND status = 'open'
  AND expires_at > $2
LIMIT 1
FOR UPDATE;

-- name: ListBidOffersBySession :many
SELECT id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare, status, created_at
FROM bid_offers
WHERE session_id = $1
ORDER BY created_at, id
LIMIT 100;

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
    proposed_fare, status
)
VALUES ($1, $2, $3, $4, $5, $6, 'pending')
RETURNING id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare, status, created_at;

-- name: CancelBidSession :one
UPDATE bid_sessions
SET status = 'cancelled'
WHERE id = $1
  AND passenger_id = $2
  AND status = 'open'
  AND expires_at > CURRENT_TIMESTAMP
RETURNING id, booking_reference, passenger_id, ride_type, pickup_latitude, pickup_longitude,
    pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name,
    passenger_note, distance_km, duration_minutes, offered_fare,
    status, target_driver_id, accepted_driver_id, expires_at, created_at;

-- name: GetPendingBidOffer :one
SELECT id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare, status, created_at
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
    proposed_fare, status, created_at;

-- name: CancelPendingBidOffer :one
UPDATE bid_offers
SET status = 'rejected'
WHERE session_id = $1
  AND driver_id = $2
  AND status = 'pending'
  AND EXISTS (
      SELECT 1 FROM bid_sessions
      WHERE id = bid_offers.session_id
        AND status = 'open'
  )
RETURNING id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare, status, created_at;

