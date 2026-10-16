LOCK TABLE private_objects IN ACCESS EXCLUSIVE MODE;

DO $migration$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM private_objects
        WHERE external_storage_key IS NULL
           OR external_verified_at IS NULL
    ) THEN
        RAISE EXCEPTION 'cannot drop private_objects.content before every MinIO object has been verified';
    END IF;
END
$migration$;

DROP INDEX private_objects_external_storage_pending_idx;

ALTER TABLE private_objects
    DROP CONSTRAINT private_objects_storage_location_check,
    DROP COLUMN content,
    ALTER COLUMN external_storage_key SET NOT NULL,
    ADD CONSTRAINT private_objects_external_storage_key_check
        CHECK (length(external_storage_key) > 0);
