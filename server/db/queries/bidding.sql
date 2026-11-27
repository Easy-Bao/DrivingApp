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
    RETURNING id, passenger_id, booking_reference, target_driver_id
), rejected_offers AS (
    UPDATE bid_offers
    SET status = 'rejected'
    WHERE status = 'pending'
      AND session_id IN (SELECT id FROM expired)
)
INSERT INTO notifications (user_id, type, title, body)
SELECT
    passenger_id,
    'ride',
    CASE
        WHEN target_driver_id IS NOT NULL THEN 'Driver timed out'
        ELSE 'Ride request timed out'
    END,
    CASE
        WHEN target_driver_id IS NOT NULL THEN 'The driver did not respond to Booking ID - ' || booking_reference || ' in time.'
        ELSE 'Your ride request for Booking ID - ' || booking_reference || ' timed out because no driver responded in time.'
    END
FROM expired;

-- name: ExpireAllElapsedBidSessions :execrows
WITH targets AS (
    SELECT bs.id
    FROM bid_sessions AS bs
    WHERE bs.status = 'open'
      AND bs.expires_at <= sqlc.arg('expires_at')::timestamptz
    ORDER BY bs.expires_at ASC
    LIMIT sqlc.arg('limit')::int
    FOR UPDATE OF bs SKIP LOCKED
), expired AS (
    UPDATE bid_sessions
    SET status = 'expired'
    WHERE bid_sessions.id IN (SELECT targets.id FROM targets)
    RETURNING bid_sessions.id, bid_sessions.passenger_id,
        bid_sessions.booking_reference, bid_sessions.target_driver_id
), rejected_offers AS (
    UPDATE bid_offers
    SET status = 'rejected'
    WHERE bid_offers.status = 'pending'
      AND bid_offers.session_id IN (SELECT expired.id FROM expired)
)
INSERT INTO notifications (user_id, type, title, body)
SELECT
    expired.passenger_id,
    'ride',
    CASE
        WHEN expired.target_driver_id IS NOT NULL THEN 'Driver timed out'
        ELSE 'Ride request timed out'
    END,
    CASE
        WHEN expired.target_driver_id IS NOT NULL THEN 'The driver did not respond to Booking ID - ' || expired.booking_reference || ' in time.'
        ELSE 'Your ride request for Booking ID - ' || expired.booking_reference || ' timed out because no driver responded in time.'
    END
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
FOR UPDATE OF driver_profiles;

-- name: CountActiveRidesForDriver :one
SELECT count(*)
FROM rides
WHERE driver_id = $1
  AND status IN ('assigned', 'accepted', 'arrived', 'in_transit');

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
WITH cancelled AS (
    UPDATE bid_sessions
    SET status = 'cancelled'
    WHERE bid_sessions.id = $1
      AND bid_sessions.passenger_id = $2
      AND bid_sessions.status = 'open'
    RETURNING bid_sessions.id, bid_sessions.booking_reference, bid_sessions.passenger_id,
        bid_sessions.ride_type, bid_sessions.pickup_latitude, bid_sessions.pickup_longitude,
        bid_sessions.pickup_name, bid_sessions.dropoff_latitude, bid_sessions.dropoff_longitude,
        bid_sessions.dropoff_name, bid_sessions.passenger_note, bid_sessions.distance_km,
        bid_sessions.duration_minutes, bid_sessions.offered_fare, bid_sessions.status,
        bid_sessions.target_driver_id, bid_sessions.accepted_driver_id,
        bid_sessions.expires_at, bid_sessions.created_at
), rejected_offers AS (
    UPDATE bid_offers
    SET status = 'rejected'
    WHERE bid_offers.session_id IN (SELECT cancelled.id FROM cancelled)
      AND bid_offers.status = 'pending'
)
SELECT cancelled.id, cancelled.booking_reference, cancelled.passenger_id,
    cancelled.ride_type, cancelled.pickup_latitude, cancelled.pickup_longitude,
    cancelled.pickup_name, cancelled.dropoff_latitude, cancelled.dropoff_longitude,
    cancelled.dropoff_name, cancelled.passenger_note, cancelled.distance_km,
    cancelled.duration_minutes, cancelled.offered_fare, cancelled.status,
    cancelled.target_driver_id, cancelled.accepted_driver_id,
    cancelled.expires_at, cancelled.created_at
FROM cancelled;

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


-- name: DeclineTargetedBidSession :one
WITH declined AS (
    UPDATE bid_sessions
    SET status = 'declined'
    WHERE bid_sessions.id = $1
      AND bid_sessions.target_driver_id = $2
      AND (
          bid_sessions.status = 'declined'
          OR (bid_sessions.status = 'open' AND bid_sessions.expires_at > clock_timestamp())
      )
    RETURNING bid_sessions.id, bid_sessions.booking_reference, bid_sessions.passenger_id,
        bid_sessions.ride_type, bid_sessions.pickup_latitude, bid_sessions.pickup_longitude,
        bid_sessions.pickup_name, bid_sessions.dropoff_latitude, bid_sessions.dropoff_longitude,
        bid_sessions.dropoff_name, bid_sessions.passenger_note, bid_sessions.distance_km,
        bid_sessions.duration_minutes, bid_sessions.offered_fare, bid_sessions.status,
        bid_sessions.target_driver_id, bid_sessions.accepted_driver_id,
        bid_sessions.expires_at, bid_sessions.created_at
), rejected_offers AS (
    UPDATE bid_offers
    SET status = 'rejected'
    WHERE bid_offers.session_id IN (SELECT declined.id FROM declined)
      AND bid_offers.status = 'pending'
)
SELECT declined.id, declined.booking_reference, declined.passenger_id,
    declined.ride_type, declined.pickup_latitude, declined.pickup_longitude,
    declined.pickup_name, declined.dropoff_latitude, declined.dropoff_longitude,
    declined.dropoff_name, declined.passenger_note, declined.distance_km,
    declined.duration_minutes, declined.offered_fare, declined.status,
    declined.target_driver_id, declined.accepted_driver_id,
    declined.expires_at, declined.created_at
FROM declined;
