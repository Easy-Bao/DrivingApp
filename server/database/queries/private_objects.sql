-- name: CreatePrivateObject :exec
INSERT INTO private_objects (
    storage_key,
    content,
    content_type,
    size_bytes,
    checksum_sha256
)
VALUES ($1, $2, $3, $4, $5);

-- name: CreateExternalPrivateObject :exec
INSERT INTO private_objects (
    storage_key,
    content,
    external_storage_key,
    content_type,
    size_bytes,
    checksum_sha256
)
VALUES ($1, NULL, $2, $3, $4, $5);

-- name: GetPrivateObjectByStorageKey :one
SELECT storage_key, content, external_storage_key, content_type, size_bytes, checksum_sha256
FROM private_objects
WHERE storage_key = $1
LIMIT 1;

-- name: GetNextPrivateObjectForExternalStorageMigration :one
SELECT id, storage_key, content, content_type, size_bytes, checksum_sha256
FROM private_objects
WHERE external_storage_key IS NULL
ORDER BY id
LIMIT 1;

-- name: SetPrivateObjectExternalStorageKey :execrows
UPDATE private_objects
SET external_storage_key = sqlc.arg('external_storage_key')
WHERE id = sqlc.arg('id')
  AND external_storage_key IS NULL
  AND size_bytes = sqlc.arg('size_bytes')
  AND checksum_sha256 = sqlc.arg('checksum_sha256');

-- name: DeletePrivateObjectByStorageKey :exec
DELETE FROM private_objects
WHERE storage_key = $1;
