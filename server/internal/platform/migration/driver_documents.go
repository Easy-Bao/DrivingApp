package migration

import (
	"context"

	"entgo.io/ent/dialect"
)

func applyPrivateDocumentMetadata(ctx context.Context, connection dialect.ExecQuerier) error {
	statements := []string{
		`ALTER TABLE driver_documents ADD COLUMN IF NOT EXISTS content_type VARCHAR(64) NOT NULL DEFAULT 'application/octet-stream'`,
		`ALTER TABLE driver_documents ADD COLUMN IF NOT EXISTS size_bytes BIGINT NOT NULL DEFAULT 0`,
		`ALTER TABLE driver_documents ADD COLUMN IF NOT EXISTS checksum_sha256 VARCHAR(64) NOT NULL DEFAULT ''`,
		`ALTER TABLE driver_documents ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`,
		`ALTER TABLE driver_documents ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ`,
		`DO $migration$
		DECLARE
			user_id_type TEXT;
		BEGIN
			IF NOT EXISTS (
				SELECT 1 FROM information_schema.columns
				WHERE table_schema = 'public'
				  AND table_name = 'driver_documents'
				  AND column_name = 'reviewed_by'
			) THEN
				SELECT format_type(attribute.atttypid, attribute.atttypmod)
				INTO user_id_type
				FROM pg_attribute AS attribute
				JOIN pg_class AS relation ON relation.oid = attribute.attrelid
				JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
				WHERE namespace.nspname = 'public'
				  AND relation.relname = 'users'
				  AND attribute.attname = 'id'
				  AND attribute.attnum > 0
				  AND NOT attribute.attisdropped;
				IF user_id_type IS NULL THEN
					RAISE EXCEPTION 'users.id type is unavailable';
				END IF;
				EXECUTE format('ALTER TABLE driver_documents ADD COLUMN reviewed_by %s', user_id_type);
			END IF;
		END
		$migration$`,
		`UPDATE driver_documents SET status = 'pending' WHERE status NOT IN ('pending', 'approved', 'rejected')`,
		`UPDATE driver_documents SET document_type = 'legacy_document' WHERE document_type !~ '^[a-z][a-z0-9_]{0,63}$'`,
		`UPDATE driver_documents SET content_type = 'application/octet-stream' WHERE content_type NOT IN ('application/octet-stream', 'application/pdf', 'image/jpeg', 'image/png')`,
		`UPDATE driver_documents SET size_bytes = 0, checksum_sha256 = '' WHERE size_bytes < 0 OR (size_bytes = 0 AND checksum_sha256 <> '') OR (size_bytes > 0 AND checksum_sha256 !~ '^[a-f0-9]{64}$')`,
		`UPDATE driver_documents SET reviewed_at = created_at WHERE status IN ('approved', 'rejected') AND reviewed_at IS NULL`,
		`UPDATE driver_documents SET reviewed_at = NULL, reviewed_by = NULL WHERE status = 'pending'`,
		`ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_status_check`,
		`ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_status_check CHECK (status IN ('pending', 'approved', 'rejected'))`,
		`ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_type_check`,
		`ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_type_check CHECK (document_type ~ '^[a-z][a-z0-9_]{0,63}$')`,
		`ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_content_type_check`,
		`ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_content_type_check CHECK (content_type IN ('application/octet-stream', 'application/pdf', 'image/jpeg', 'image/png'))`,
		`ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_integrity_check`,
		`ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_integrity_check CHECK ((size_bytes = 0 AND checksum_sha256 = '') OR (size_bytes > 0 AND checksum_sha256 ~ '^[a-f0-9]{64}$'))`,
		`ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_review_check`,
		`ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_review_check CHECK ((status = 'pending' AND reviewed_at IS NULL AND reviewed_by IS NULL) OR (status IN ('approved', 'rejected') AND reviewed_at IS NOT NULL))`,
		addForeignKey("driver_documents_reviewer_fk", "driver_documents", "reviewed_by", "users", "id", "SET NULL"),
		validateForeignKey("driver_documents", "driver_documents_reviewer_fk"),
		`CREATE INDEX IF NOT EXISTS driver_document_driver_type_created_at ON driver_documents (driver_id, document_type, created_at)`,
		`CREATE INDEX IF NOT EXISTS driver_document_status_created_at ON driver_documents (status, created_at)`,
		`DROP INDEX IF EXISTS driverdocument_driver_id_document_type`,
	}
	return executeStatements(ctx, connection, statements)
}
