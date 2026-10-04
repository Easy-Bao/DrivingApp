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
    driver_rating, created_at, completed_at, payment_status,
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
