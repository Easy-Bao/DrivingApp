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
