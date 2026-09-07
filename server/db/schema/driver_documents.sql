CREATE TABLE driver_documents (
    id serial PRIMARY KEY,
    driver_id integer NOT NULL,
    document_type varchar(64) NOT NULL,
    storage_key varchar(160) NOT NULL,
    status varchar(16) NOT NULL DEFAULT 'pending',
    content_type varchar(64) NOT NULL DEFAULT 'application/octet-stream',
    size_bytes bigint NOT NULL DEFAULT 0,
    checksum_sha256 varchar(64) NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at timestamptz,
    reviewed_by integer
);

CREATE INDEX driver_document_driver_type_created_at
    ON driver_documents (driver_id, document_type, created_at);

CREATE INDEX driver_document_status_created_at
    ON driver_documents (status, created_at);
