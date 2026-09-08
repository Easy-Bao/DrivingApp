ALTER TABLE private_objects
    ALTER COLUMN id TYPE bigint,
    ALTER COLUMN storage_key TYPE text,
    ALTER COLUMN content_type TYPE text,
    ALTER COLUMN checksum_sha256 TYPE text,
    ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE private_objects
    ALTER COLUMN id DROP DEFAULT;

ALTER SEQUENCE private_objects_id_seq OWNED BY NONE;
ALTER SEQUENCE private_objects_id_seq RENAME TO private_objects_id_serial_seq;

ALTER TABLE private_objects
    ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
        SEQUENCE NAME private_objects_id_seq
    );

SELECT setval(
    pg_get_serial_sequence('private_objects', 'id'),
    COALESCE(MAX(id), 1),
    COUNT(*) > 0
)
FROM private_objects;

ALTER TABLE private_objects
    ADD CONSTRAINT private_objects_size_bytes_check
        CHECK (size_bytes >= 0),
    ADD CONSTRAINT private_objects_checksum_sha256_check
        CHECK (
            length(checksum_sha256) = 64
            AND checksum_sha256 ~ '^[0-9a-fA-F]{64}$'
        );

DROP SEQUENCE private_objects_id_serial_seq;
