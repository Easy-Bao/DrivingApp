-- name: UpdateRideStatus :one
UPDATE rides
SET status = sqlc.arg('next_status'),
    cancelled_by = COALESCE(sqlc.narg('cancelled_by')::integer, cancelled_by),
    cancellation_reason = COALESCE(sqlc.narg('cancellation_reason')::text, cancellation_reason),
    cancellation_responsibility = COALESCE(
        sqlc.narg('cancellation_responsibility')::text,
        cancellation_responsibility
    ),
    cancellation_details = COALESCE(sqlc.narg('cancellation_details')::text, cancellation_details),
    completed_at = COALESCE(sqlc.narg('completed_at')::timestamptz, completed_at)
WHERE id = sqlc.arg('ride_id')
  AND status = sqlc.arg('current_status')
  AND (passenger_id = sqlc.arg('actor_id') OR driver_id = sqlc.arg('actor_id'))
RETURNING id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, arrived_at, waiting_until, payment_status,
    cash_received_at, cash_received_amount, cash_change_amount, cash_outcome,
    cancelled_by, cancellation_reason, cancellation_responsibility,
    cancellation_details,
    commission_bps, commission_amount,
    driver_payout_amount;

-- name: MarkRideArrived :one
UPDATE rides
SET status = 'arrived',
    arrived_at = COALESCE(arrived_at, CURRENT_TIMESTAMP),
    waiting_until = COALESCE(
        waiting_until,
        CURRENT_TIMESTAMP + make_interval(secs => sqlc.arg('wait_seconds')::integer)
    )
WHERE id = sqlc.arg('ride_id')
  AND driver_id = sqlc.arg('driver_id')
  AND status = sqlc.arg('current_status')
  AND sqlc.arg('current_status') IN ('assigned', 'accepted')
RETURNING id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, arrived_at, waiting_until, payment_status,
    cash_received_at, cash_received_amount, cash_change_amount, cash_outcome,
    cancelled_by, cancellation_reason, cancellation_responsibility,
    cancellation_details,
    commission_bps, commission_amount,
    driver_payout_amount;

-- name: MarkRidePassengerNoShow :one
UPDATE rides
SET status = 'cancelled',
    completed_at = CURRENT_TIMESTAMP,
    cancelled_by = sqlc.arg('driver_id'),
    cancellation_reason = 'passenger_no_show',
    cancellation_responsibility = 'passenger_fault',
    cancellation_details = 'Driver completed the server-enforced pickup wait.',
    arrived_at = COALESCE(arrived_at, CURRENT_TIMESTAMP),
    waiting_until = COALESCE(waiting_until, CURRENT_TIMESTAMP)
WHERE id = sqlc.arg('ride_id')
  AND driver_id = sqlc.arg('driver_id')
  AND status = 'arrived'
  AND waiting_until IS NOT NULL
  AND waiting_until <= CURRENT_TIMESTAMP
RETURNING id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, arrived_at, waiting_until, payment_status,
    cash_received_at, cash_received_amount, cash_change_amount, cash_outcome,
    cancelled_by, cancellation_reason, cancellation_responsibility,
    cancellation_details,
    commission_bps, commission_amount,
    driver_payout_amount;

-- name: StartRide :one
UPDATE rides
SET status = 'in_transit'
WHERE id = sqlc.arg('ride_id')
  AND driver_id = sqlc.arg('driver_id')
  AND status = 'arrived'
RETURNING id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, arrived_at, waiting_until, payment_status,
    cash_received_at, cash_received_amount, cash_change_amount, cash_outcome,
    cancelled_by, cancellation_reason, cancellation_responsibility,
    cancellation_details,
    commission_bps, commission_amount,
    driver_payout_amount;

-- name: CompleteRide :one
UPDATE rides
SET status = 'completed',
    completed_at = COALESCE(completed_at, CURRENT_TIMESTAMP)
WHERE id = sqlc.arg('ride_id')
  AND driver_id = sqlc.arg('driver_id')
  AND status = 'in_transit'
RETURNING id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, arrived_at, waiting_until, payment_status,
    cash_received_at, cash_received_amount, cash_change_amount, cash_outcome,
    cancelled_by, cancellation_reason, cancellation_responsibility,
    cancellation_details,
    commission_bps, commission_amount,
    driver_payout_amount;

-- name: CreateRideEvent :exec
INSERT INTO ride_events (
    ride_id, actor_id, event_type, from_status, to_status,
    reason, responsibility, details, request_id
)
VALUES (
    sqlc.arg('ride_id'), sqlc.arg('actor_id'), sqlc.arg('event_type'),
    sqlc.arg('from_status'), sqlc.arg('to_status'), sqlc.arg('reason'),
    sqlc.arg('responsibility'), sqlc.arg('details'), sqlc.arg('request_id')
);
