-- name: ListDriverRides :many
SELECT sqlc.embed(r)
FROM rides AS r
WHERE r.driver_id = sqlc.arg('driver_id')
  AND (
      sqlc.arg('active_only')::boolean = false
      OR r.status IN ('assigned', 'accepted', 'arrived', 'in_transit')
  )
ORDER BY r.created_at DESC, r.id DESC
LIMIT sqlc.arg('limit')::int
OFFSET sqlc.arg('offset')::int;

-- name: ListPassengerRides :many
SELECT sqlc.embed(r)
FROM rides AS r
WHERE r.passenger_id = sqlc.arg('passenger_id')
ORDER BY r.created_at DESC, r.id DESC
LIMIT sqlc.arg('limit')::int
OFFSET sqlc.arg('offset')::int;

-- name: ListRecentPassengerRides :many
SELECT sqlc.embed(r)
FROM rides AS r
WHERE r.passenger_id = sqlc.arg('passenger_id')
ORDER BY r.id DESC
LIMIT sqlc.arg('limit')::int;
