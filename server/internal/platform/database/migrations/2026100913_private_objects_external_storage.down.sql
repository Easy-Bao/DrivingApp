DO $migration$
BEGIN
    IF EXISTS (SELECT 1 FROM private_objects WHERE content IS NULL) THEN
        RAISE EXCEPTION 'cannot roll back external object storage while private_objects contains MinIO-only records';
    END IF;
END
$migration$;

DROP INDEX private_objects_external_storage_pending_idx;

ALTER TABLE private_objects
    DROP CONSTRAINT private_objects_storage_location_check,
    DROP COLUMN external_storage_key,
    ALTER COLUMN content SET NOT NULL;
