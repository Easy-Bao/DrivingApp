-- name: UpdateRideStatus :one
UPDATE rides
SET status = sqlc.arg('next_status'),
    completed_at = COALESCE(sqlc.narg('completed_at')::timestamptz, completed_at)
WHERE id = sqlc.arg('ride_id')
  AND status = sqlc.arg('current_status')
  AND (passenger_id = sqlc.arg('actor_id') OR driver_id = sqlc.arg('actor_id'))
RETURNING id, passenger_id, driver_id, status, fare_centavos, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, payment_status,
    cash_received_at, commission_bps, commission_centavos,
    driver_payout_centavos;
