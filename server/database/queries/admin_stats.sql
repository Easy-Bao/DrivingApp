-- name: CountUsers :one
SELECT count(*)
FROM users;

-- name: CountRides :one
SELECT count(*)
FROM rides;

-- name: CountDriverDocuments :one
SELECT count(*)
FROM driver_documents;
