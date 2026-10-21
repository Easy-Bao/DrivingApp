-- name: LockRequestedRideForAcceptance :one
SELECT id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, arrived_at, waiting_until,
    cancelled_by, cancellation_reason, cancellation_responsibility,
    cancellation_details
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

-- name: GetBidOfferDriverForAcceptance :one
SELECT driver_id
FROM bid_offers
WHERE id = $1
  AND session_id = $2
  AND status = 'pending'
LIMIT 1;

-- name: MarkBidOfferAccepted :one
UPDATE bid_offers
SET status = 'accepted'
WHERE id = $1
  AND status = 'pending'
RETURNING id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare, status, created_at;

-- name: RejectOtherPendingBidOffers :many
UPDATE bid_offers
SET status = 'rejected'
WHERE session_id = $1
  AND status = 'pending'
  AND id <> $2
RETURNING id, session_id, driver_id, driver_name, plate_number, vehicle_type,
    proposed_fare, status, created_at;

-- name: RejectDriverPendingBidOffers :many
WITH rejected AS (
    UPDATE bid_offers
    SET status = 'rejected'
    WHERE bid_offers.driver_id = $1
      AND bid_offers.status = 'pending'
      AND bid_offers.id <> $2
    RETURNING bid_offers.id, bid_offers.session_id, bid_offers.driver_id,
        bid_offers.driver_name, bid_offers.plate_number,
        bid_offers.vehicle_type, bid_offers.proposed_fare,
        bid_offers.status, bid_offers.created_at
)
SELECT rejected.id AS offer_id,
    rejected.session_id AS offer_session_id,
    rejected.driver_id AS offer_driver_id,
    rejected.driver_name AS offer_driver_name,
    rejected.plate_number AS offer_plate_number,
    rejected.vehicle_type AS offer_vehicle_type,
    rejected.proposed_fare AS offer_proposed_fare,
    rejected.status AS offer_status,
    rejected.created_at AS offer_created_at,
    sqlc.embed(bid_sessions)
FROM rejected
JOIN bid_sessions ON bid_sessions.id = rejected.session_id
ORDER BY rejected.id;

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
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number
)
VALUES (
    $1, $2, 'accepted', $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
    $13, $14, $15
)
RETURNING *;

-- name: AssignRideFromAcceptance :one
UPDATE rides
SET status = 'assigned',
    driver_id = $2,
    driver_name = $3,
    vehicle_type = $4,
    plate_number = $5
WHERE id = $1
  AND status = 'requested'
RETURNING *;

-- name: AcceptRideFromRequest :one
UPDATE rides
SET status = 'accepted',
    driver_id = $2,
    driver_name = $3,
    vehicle_type = $4,
    plate_number = $5
WHERE id = $1
  AND status = 'requested'
RETURNING *;

-- name: CreateRideSettlement :one
INSERT INTO ride_settlements (
    ride_id, gross_fare, commission_bps, commission_amount,
    driver_payout_amount, payment_status
)
VALUES ($1, $2, $3, $4, $5, 'unpaid')
RETURNING id, ride_id, gross_fare, commission_bps, commission_amount,
    driver_payout_amount, payment_status, cash_received_at,
    cash_received_amount, cash_change_amount, cash_outcome, settled_at,
    created_at, updated_at;
