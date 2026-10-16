ALTER TABLE private_objects
    ADD COLUMN external_storage_key text,
    ALTER COLUMN content DROP NOT NULL;

ALTER TABLE private_objects
    ADD CONSTRAINT private_objects_storage_location_check
        CHECK (content IS NOT NULL OR external_storage_key IS NOT NULL) NOT VALID;

CREATE INDEX private_objects_external_storage_pending_idx
    ON private_objects (id)
    WHERE external_storage_key IS NULL;
