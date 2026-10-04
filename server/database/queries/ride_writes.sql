-- name: CreateRide :one
INSERT INTO rides (
    passenger_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
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
