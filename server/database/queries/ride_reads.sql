-- name: GetRideByID :one
SELECT id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, arrived_at, waiting_until, payment_status,
    cash_received_at, cash_received_amount, cash_change_amount, cash_outcome,
    cancelled_by, cancellation_reason, cancellation_responsibility,
    cancellation_details,
    commission_bps, commission_amount,
    driver_payout_amount
FROM rides
WHERE id = $1
LIMIT 1;

-- name: ListActiveRidesForDriver :many
SELECT id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, arrived_at, waiting_until, payment_status,
    cash_received_at, cash_received_amount, cash_change_amount, cash_outcome,
    cancelled_by, cancellation_reason, cancellation_responsibility,
    cancellation_details,
    commission_bps, commission_amount,
    driver_payout_amount
FROM rides
WHERE driver_id = $1
  AND status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit')
ORDER BY id;
