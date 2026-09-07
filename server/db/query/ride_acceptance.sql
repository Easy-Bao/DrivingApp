-- name: LockPendingBidForAcceptance :one
SELECT id, ride_id, driver_id, offered_fare_centavos, status
FROM bids
WHERE id = $1
  AND driver_id = $2
  AND status = 'pending'
LIMIT 1
FOR UPDATE;

-- name: MarkBidAccepted :one
UPDATE bids
SET status = 'accepted'
WHERE id = $1
  AND status = 'pending'
RETURNING id, ride_id, driver_id, offered_fare_centavos, status;

-- name: LockRequestedRideForAcceptance :one
SELECT id, passenger_id, driver_id, status, fare_centavos, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, payment_status,
    cash_received_at, commission_bps, commission_centavos,
    driver_payout_centavos
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

-- name: AssignRideFromAcceptance :one
UPDATE rides
SET status = 'assigned',
    driver_id = $2,
    driver_name = $3,
    vehicle_type = $4,
    plate_number = $5,
    commission_bps = $6,
    commission_centavos = $7,
    driver_payout_centavos = $8
WHERE id = $1
  AND status = 'requested'
RETURNING id, passenger_id, driver_id, status, fare_centavos, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, payment_status,
    cash_received_at, commission_bps, commission_centavos,
    driver_payout_centavos;

-- name: CreateRideSettlement :exec
INSERT INTO ride_settlements (
    ride_id, gross_fare_centavos, commission_bps, commission_centavos,
    driver_payout_centavos, payment_status
)
VALUES ($1, $2, $3, $4, $5, 'unpaid');
