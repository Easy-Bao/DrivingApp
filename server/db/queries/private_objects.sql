-- name: CreateExternalPrivateObject :exec
INSERT INTO private_objects (
    storage_key,
    external_storage_key,
    content_type,
    size_bytes,
    checksum_sha256
)
VALUES ($1, $2, $3, $4, $5);

-- name: GetPrivateObjectByStorageKey :one
SELECT storage_key, COALESCE(external_storage_key, '')::text AS external_storage_key,
    content_type, size_bytes, checksum_sha256
FROM private_objects
WHERE storage_key = $1
LIMIT 1;

-- name: GetNextPrivateObjectForExternalStorageMigration :one
SELECT id, storage_key, content_type, size_bytes, checksum_sha256
FROM private_objects
WHERE external_storage_key IS NULL
ORDER BY id
LIMIT 1;

-- name: SetPrivateObjectExternalStorageKey :execrows
UPDATE private_objects
SET external_storage_key = sqlc.arg('external_storage_key'),
    external_verified_at = now()
WHERE id = sqlc.arg('id')
  AND external_storage_key IS NULL
  AND size_bytes = sqlc.arg('size_bytes')
  AND checksum_sha256 = sqlc.arg('checksum_sha256');

-- name: CountPrivateObjectsPendingExternalStorage :one
SELECT count(*)::bigint
FROM private_objects
WHERE external_storage_key IS NULL OR external_verified_at IS NULL;

-- name: GetNextExternalPrivateObjectForVerification :one
SELECT id, storage_key, external_storage_key, content_type, size_bytes,
    checksum_sha256
FROM private_objects
WHERE id > sqlc.arg('after_id')
  AND external_storage_key IS NOT NULL
ORDER BY id
LIMIT 1;

-- name: SetPrivateObjectExternalStorageVerifiedAt :execrows
UPDATE private_objects
SET external_verified_at = now()
WHERE id = sqlc.arg('id')
  AND external_storage_key = sqlc.arg('external_storage_key')
  AND size_bytes = sqlc.arg('size_bytes')
  AND checksum_sha256 = sqlc.arg('checksum_sha256');

-- name: DeletePrivateObjectByStorageKey :exec
DELETE FROM private_objects
WHERE storage_key = $1;
