-- name: LockRequestedRideForAcceptance :one
SELECT id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, payment_status,
    cash_received_at, commission_bps, commission_amount,
    driver_payout_amount
FROM rides
WHERE id = $1
  AND status = 'requested'
LIMIT 1
FOR UPDATE;

-- name: CountActiveRidesForAcceptance :one
SELECT count(*)
FROM rides
WHERE driver_id = $1
  AND status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit');

-- name: LockPendingBidOfferForAcceptance :one
SELECT id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare, status, created_at
FROM bid_offers
WHERE id = $1
  AND session_id = $2
  AND status = 'pending'
LIMIT 1
FOR UPDATE;

-- name: MarkBidOfferAccepted :one
UPDATE bid_offers
SET status = 'accepted'
WHERE id = $1
  AND status = 'pending'
RETURNING id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare, status, created_at;

-- name: RejectOtherPendingBidOffers :exec
UPDATE bid_offers
SET status = 'rejected'
WHERE session_id = $1
  AND status = 'pending'
  AND id <> $2;

-- name: MarkBidSessionAccepted :one
UPDATE bid_sessions
SET status = 'accepted',
    accepted_driver_id = $2
WHERE id = $1
  AND status = 'open'
RETURNING id, passenger_id, ride_type, pickup_latitude, pickup_longitude,
    pickup_name, dropoff_latitude, dropoff_longitude, dropoff_name,
    passenger_note, distance_km, duration_minutes, offered_fare,
    status, target_driver_id, accepted_driver_id, expires_at, created_at;

-- name: CreateAcceptedRide :one
INSERT INTO rides (
    passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    commission_bps, commission_amount, driver_payout_amount
)
VALUES (
    $1, $2, 'accepted', $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
    $13, $14, $15, $16, $17, $18
)
RETURNING id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, payment_status,
    cash_received_at, commission_bps, commission_amount,
    driver_payout_amount;

-- name: AssignRideFromAcceptance :one
UPDATE rides
SET status = 'assigned',
    driver_id = $2,
    driver_name = $3,
    vehicle_type = $4,
    plate_number = $5,
    commission_bps = $6,
    commission_amount = $7,
    driver_payout_amount = $8
WHERE id = $1
  AND status = 'requested'
RETURNING id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, payment_status,
    cash_received_at, commission_bps, commission_amount,
    driver_payout_amount;

-- name: AcceptRideFromRequest :one
UPDATE rides
SET status = 'accepted',
    driver_id = $2,
    driver_name = $3,
    vehicle_type = $4,
    plate_number = $5,
    commission_bps = $6,
    commission_amount = $7,
    driver_payout_amount = $8
WHERE id = $1
  AND status = 'requested'
RETURNING id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, payment_status,
    cash_received_at, commission_bps, commission_amount,
    driver_payout_amount;

-- name: CreateRideSettlement :exec
INSERT INTO ride_settlements (
    ride_id, gross_fare, commission_bps, commission_amount,
    driver_payout_amount, payment_status
)
VALUES ($1, $2, $3, $4, $5, 'unpaid');
