-- name: CreateDriverDocument :one
INSERT INTO driver_documents (
    driver_id,
    document_type,
    storage_key,
    status,
    content_type,
    size_bytes,
    checksum_sha256
)
VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING id, driver_id, document_type, storage_key, status, content_type,
    size_bytes, checksum_sha256, created_at, reviewed_at, reviewed_by;

-- name: GetDriverDocumentByID :one
SELECT id, driver_id, document_type, storage_key, status, content_type,
    size_bytes, checksum_sha256, created_at, reviewed_at, reviewed_by
FROM driver_documents
WHERE id = $1
LIMIT 1;

-- name: ListDriverDocumentsByDriverID :many
SELECT id, driver_id, document_type, storage_key, status, content_type,
    size_bytes, checksum_sha256, created_at, reviewed_at, reviewed_by
FROM driver_documents
WHERE driver_id = $1
ORDER BY created_at DESC, id DESC
LIMIT $2;

-- name: ListDriverDocumentsForReview :many
SELECT id, driver_id, document_type, storage_key, status, content_type,
    size_bytes, checksum_sha256, created_at, reviewed_at, reviewed_by
FROM driver_documents
WHERE status = $1
ORDER BY created_at ASC, id ASC
LIMIT $2 OFFSET $3;

-- name: ReviewDriverDocument :one
UPDATE driver_documents
SET status = $2, reviewed_at = $3, reviewed_by = $4
WHERE id = $1
  AND status = 'pending'
RETURNING id, driver_id, document_type, storage_key, status, content_type,
    size_bytes, checksum_sha256, created_at, reviewed_at, reviewed_by;
