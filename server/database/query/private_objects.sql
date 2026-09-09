-- name: CreatePrivateObject :exec
INSERT INTO private_objects (
    storage_key,
    content,
    content_type,
    size_bytes,
    checksum_sha256
)
VALUES ($1, $2, $3, $4, $5);

-- name: GetPrivateObjectByStorageKey :one
SELECT storage_key, content, content_type, size_bytes, checksum_sha256
FROM private_objects
WHERE storage_key = $1
LIMIT 1;

-- name: DeletePrivateObjectByStorageKey :exec
DELETE FROM private_objects
WHERE storage_key = $1;
