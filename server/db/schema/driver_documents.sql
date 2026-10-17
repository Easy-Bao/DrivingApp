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
    reviewed_by integer,
    CONSTRAINT driver_documents_status_check
        CHECK (status IN ('pending', 'approved', 'rejected')),
    CONSTRAINT driver_documents_type_check
        CHECK (document_type ~ '^[a-z][a-z0-9_]{0,63}$'),
    CONSTRAINT driver_documents_content_type_check
        CHECK (content_type IN ('application/octet-stream', 'application/pdf', 'image/jpeg', 'image/png')),
    CONSTRAINT driver_documents_integrity_check
        CHECK (
            (size_bytes = 0 AND checksum_sha256 = '')
            OR (size_bytes > 0 AND checksum_sha256 ~ '^[a-f0-9]{64}$')
        ),
    CONSTRAINT driver_documents_review_check
        CHECK (
            (status = 'pending' AND reviewed_at IS NULL AND reviewed_by IS NULL)
            OR (status IN ('approved', 'rejected') AND reviewed_at IS NOT NULL)
        ),
    CONSTRAINT driver_documents_driver_fk
        FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT driver_documents_reviewer_fk
        FOREIGN KEY (reviewed_by) REFERENCES users (id) ON DELETE SET NULL
);

CREATE INDEX driver_document_driver_type_created_at
    ON driver_documents (driver_id, document_type, created_at);

CREATE INDEX driver_document_status_created_at
    ON driver_documents (status, created_at);

CREATE INDEX driver_document_reviewer_id_idx
    ON driver_documents (reviewed_by)
    WHERE reviewed_by IS NOT NULL;
