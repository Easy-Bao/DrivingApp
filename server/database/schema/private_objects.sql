-- TODO(architecture): Scale Out Storage Engine (Recommendation 3)
-- Currently, raw binary payloads are stored inline as BYTEA in private_objects.
-- When scaling to high user volumes, migrate content payloads to S3/MinIO compatible object
-- storage with pre-signed upload/download URLs. Retain storage_key, checksum_sha256,
-- size_bytes, and metadata in PostgreSQL, while dropping the inline BYTEA column to prevent
-- database buffer cache thrashing, WAL volume bloat, and backup degradation.
-- See: database/OBJECT_STORAGE_MIGRATION.md for migration architecture.

CREATE TABLE private_objects (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    storage_key text NOT NULL,
    content bytea NOT NULL,
    content_type text NOT NULL,
    size_bytes bigint NOT NULL,
    checksum_sha256 text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT private_objects_storage_key_key UNIQUE (storage_key),
    CONSTRAINT private_objects_size_bytes_check CHECK (size_bytes >= 0),
    CONSTRAINT private_objects_checksum_sha256_check CHECK (
        length(checksum_sha256) = 64
        AND checksum_sha256 ~ '^[0-9a-fA-F]{64}$'
    )
);
