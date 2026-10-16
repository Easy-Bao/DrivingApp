-- name: CreateRideReport :one
INSERT INTO ride_reports (
    ride_id,
    reporter_id,
    reported_user_id,
    reporter_role,
    category,
    severity,
    description
)
SELECT
    ride.id,
    sqlc.arg('reporter_id'),
    CASE
        WHEN sqlc.arg('reporter_role')::text = 'passenger' THEN ride.driver_id
        ELSE ride.passenger_id
    END,
    sqlc.arg('reporter_role'),
    sqlc.arg('category'),
    sqlc.arg('severity'),
    sqlc.arg('description')
FROM rides AS ride
WHERE ride.id = sqlc.arg('ride_id')
  AND ride.driver_id IS NOT NULL
  AND (
      (sqlc.arg('reporter_role')::text = 'passenger' AND ride.passenger_id = sqlc.arg('reporter_id'))
      OR
      (sqlc.arg('reporter_role')::text = 'driver' AND ride.driver_id = sqlc.arg('reporter_id'))
  )
RETURNING id, ride_id, reporter_id, reported_user_id, reporter_role,
    category, severity, description, status, created_at;

-- name: GetRideReportByReporterCategory :one
SELECT id, ride_id, reporter_id, reported_user_id, reporter_role,
    category, severity, description, status, created_at
FROM ride_reports
WHERE ride_id = $1
  AND reporter_id = $2
  AND category = $3
LIMIT 1;
