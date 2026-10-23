-- name: GetRideReviewContext :one
SELECT id, passenger_id, driver_id, status
FROM rides
WHERE id = sqlc.arg('ride_id')
LIMIT 1;

-- name: ListDriverReviews :many
SELECT
    review.id,
    review.ride_id,
    review.driver_id,
    review.passenger_id,
    CASE
        WHEN NULLIF(BTRIM(review.passenger_name), '') IS NOT NULL THEN review.passenger_name
        ELSE COALESCE(NULLIF(BTRIM(passenger_profile.name), ''), BTRIM(user_account.name), '')
    END::text AS passenger_name,
    review.rating,
    review.comment,
    review.created_at
FROM reviews AS review
LEFT JOIN users AS user_account ON user_account.id = review.passenger_id
LEFT JOIN passenger_profiles AS passenger_profile ON passenger_profile.user_id = review.passenger_id
WHERE review.driver_id = sqlc.arg('driver_id')
AND (sqlc.narg('before_created_at')::timestamptz IS NULL
       OR (review.created_at, review.id) < (sqlc.narg('before_created_at')::timestamptz, sqlc.arg('before_id')::int))
ORDER BY review.created_at DESC, review.id DESC
OFFSET sqlc.arg('offset')::int
LIMIT sqlc.arg('limit')::int;

-- name: GetPassengerName :one
SELECT COALESCE(
    NULLIF(BTRIM(passenger_profile.name), ''),
    BTRIM(user_account.name),
    ''
)::text AS name
FROM users AS user_account
LEFT JOIN passenger_profiles AS passenger_profile ON passenger_profile.user_id = user_account.id
WHERE user_account.id = sqlc.arg('passenger_id');

-- name: HasReviewForRide :one
SELECT EXISTS(
    SELECT 1
    FROM reviews
    WHERE ride_id = sqlc.arg('ride_id')
) AS exists;

-- name: GetReviewByRide :one
SELECT id, ride_id, driver_id, passenger_id, passenger_name, rating, comment, created_at
FROM reviews
WHERE ride_id = sqlc.arg('ride_id')
LIMIT 1;

-- name: GetDriverReviewByRideAndPassenger :one
SELECT id, ride_id, driver_id, passenger_id, passenger_name, rating, comment, created_at
FROM reviews
WHERE ride_id = sqlc.arg('ride_id')
  AND passenger_id = sqlc.arg('passenger_id')
LIMIT 1;

-- name: CreateReview :one
INSERT INTO reviews (
    ride_id,
    driver_id,
    passenger_id,
    passenger_name,
    rating,
    comment
)
VALUES (
    sqlc.arg('ride_id'),
    sqlc.arg('driver_id'),
    sqlc.arg('passenger_id'),
    sqlc.arg('passenger_name'),
    sqlc.arg('rating'),
    sqlc.arg('comment')
)
RETURNING id, ride_id, driver_id, passenger_id, passenger_name, rating, comment, created_at;

-- name: HasPassengerReviewForRide :one
SELECT EXISTS(
    SELECT 1
    FROM passenger_reviews
    WHERE ride_id = sqlc.arg('ride_id')
) AS exists;

-- name: GetPassengerReviewByRide :one
SELECT id, ride_id, driver_id, passenger_id, rating, comment, created_at
FROM passenger_reviews
WHERE ride_id = sqlc.arg('ride_id')
LIMIT 1;

-- name: CreatePassengerReview :one
INSERT INTO passenger_reviews (
    ride_id,
    driver_id,
    passenger_id,
    rating,
    comment
)
VALUES (
    sqlc.arg('ride_id'),
    sqlc.arg('driver_id'),
    sqlc.arg('passenger_id'),
    sqlc.arg('rating'),
    sqlc.arg('comment')
)
RETURNING id, ride_id, driver_id, passenger_id, rating, comment, created_at;
