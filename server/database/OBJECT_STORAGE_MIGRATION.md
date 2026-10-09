# Private Object Storage Migration

## Current rollout

MinIO is the selected backend. `storage.ObjectStore` remains the feature boundary; the MinIO adapter stores new objects in the private bucket and keeps their key, MIME type, size, and SHA-256 in PostgreSQL. PostgreSQL-backed objects remain readable, and migrated objects continue to keep their original `BYTEA` copy for fallback.

The authenticated avatar and KYC endpoints still proxy bounded uploads through the API. They do not expose bucket URLs or MinIO credentials. Direct client uploads and pre-signed URLs would change the mobile API contract and are outside this migration.

## Rollout steps

1. Apply `2026100913_private_objects_external_storage` and deploy the API with MinIO configured and `MINIO_WRITE_ENABLED=false`. During a rolling deployment, this keeps writes readable by older API instances.
2. After all PostgreSQL-only API instances are stopped, set `MINIO_WRITE_ENABLED=true`. New objects are then stored in MinIO with metadata in PostgreSQL.
3. Copy legacy objects after the application rollout:

   ```sh
   docker compose --profile ops run --rm objectstorage-migrate
   ```

   The command processes one object at a time, validates its PostgreSQL size, MIME type, and checksum, copies it under the same key, reads it back, verifies the copy, and only then records the external key. It is safe to rerun after interruption. The original PostgreSQL bytes remain as a fallback.
4. Check migration progress with:

   ```sql
   SELECT count(*)
   FROM private_objects
   WHERE external_storage_key IS NULL;
   ```

   Run this after new writes have been switched to MinIO and the copy command has completed.

## Data retention and rollback

This rollout adds an external key and makes `content` nullable so MinIO-only writes can be represented. It does not drop the `content` column or clear legacy bytes. The down migration refuses to run while any row has no PostgreSQL copy. Removing `BYTEA` is a separate contraction and requires separate authorization after external copies have been verified and the rollback window has closed.

The application prefers a verified MinIO read when an external key exists. If MinIO is unavailable or the external copy fails integrity checks, it uses the retained PostgreSQL copy when one exists. MinIO-only objects return an error when the external object is unavailable.
