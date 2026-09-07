CREATE TABLE private_objects (
    id serial PRIMARY KEY,
    storage_key varchar(80) NOT NULL UNIQUE,
    content bytea NOT NULL,
    content_type varchar(128) NOT NULL,
    size_bytes bigint NOT NULL,
    checksum_sha256 varchar(64) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
