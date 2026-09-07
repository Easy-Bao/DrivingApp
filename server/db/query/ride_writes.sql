-- name: CreateRide :one
INSERT INTO rides (
    passenger_id, status, fare_centavos, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
RETURNING id, passenger_id, driver_id, status, fare_centavos, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, payment_status,
    cash_received_at, commission_bps, commission_centavos,
    driver_payout_centavos;

-- name: LockRequestedRideForBid :one
SELECT id
FROM rides
WHERE id = $1
  AND status = 'requested'
FOR UPDATE;

-- name: HasPendingBid :one
SELECT EXISTS (
    SELECT 1
    FROM bids
    WHERE ride_id = $1
      AND driver_id = $2
      AND status = 'pending'
);

-- name: CreateBid :one
INSERT INTO bids (ride_id, driver_id, offered_fare_centavos, status)
VALUES ($1, $2, $3, $4)
RETURNING id, ride_id, driver_id, offered_fare_centavos, status;
