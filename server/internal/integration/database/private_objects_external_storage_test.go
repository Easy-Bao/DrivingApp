//go:build integration

package database_test

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
)

func TestPrivateObjectsExternalStorageMigrationKeepsLegacyBytesAndGuardsRollback(t *testing.T) {
	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	admin, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatalf("connect to test PostgreSQL database: %v", err)
	}

	schemaName := fmt.Sprintf("private_object_storage_it_%d", time.Now().UnixNano())
	quotedSchema := pgx.Identifier{schemaName}.Sanitize()
	if _, err := admin.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		_ = admin.Close(context.Background())
		t.Fatalf("create isolated test schema: %v", err)
	}

	var connection *pgx.Conn
	t.Cleanup(func() {
		cleanupContext, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		if connection != nil {
			_ = connection.Close(cleanupContext)
		}
		_, _ = admin.Exec(cleanupContext, "DROP SCHEMA "+quotedSchema+" CASCADE")
		_ = admin.Close(cleanupContext)
	})

	config, err := pgx.ParseConfig(databaseURL)
	if err != nil {
		t.Fatalf("parse test PostgreSQL connection: %v", err)
	}
	config.RuntimeParams["search_path"] = schemaName
	connection, err = pgx.ConnectConfig(ctx, config)
	if err != nil {
		t.Fatalf("connect to isolated test schema: %v", err)
	}
	_, err = connection.Exec(ctx, `
CREATE TABLE private_objects (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    storage_key text NOT NULL UNIQUE,
    content bytea NOT NULL,
    content_type text NOT NULL,
    size_bytes bigint NOT NULL,
    checksum_sha256 text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO private_objects (storage_key, content, content_type, size_bytes, checksum_sha256)
VALUES ('db/v1/legacy', decode('010203', 'hex'), 'application/octet-stream', 3, 'legacy-checksum');`)
	if err != nil {
		t.Fatalf("create and seed legacy private_objects table: %v", err)
	}

	if err := executeEmbeddedMigration(ctx, connection, "2026100913_private_objects_external_storage.up.sql"); err != nil {
		t.Fatalf("apply external storage expansion: %v", err)
	}
	var content, externalStorageKey []byte
	if err := connection.QueryRow(ctx, `
SELECT content, external_storage_key
FROM private_objects
WHERE storage_key = 'db/v1/legacy'`).Scan(&content, &externalStorageKey); err != nil {
		t.Fatalf("read legacy private object after expansion: %v", err)
	}
	if string(content) != string([]byte{1, 2, 3}) || externalStorageKey != nil {
		t.Fatalf("legacy object after expansion = content %v, external key %q", content, externalStorageKey)
	}
	if _, err := connection.Exec(ctx, `
INSERT INTO private_objects (storage_key, content, external_storage_key, content_type, size_bytes, checksum_sha256)
VALUES ('minio/v1/external-only', NULL, 'minio/v1/external-only', 'application/octet-stream', 3, 'external-checksum')`); err != nil {
		t.Fatalf("insert external-only private object: %v", err)
	}
	if _, err := connection.Exec(ctx, `
INSERT INTO private_objects (storage_key, content, external_storage_key, content_type, size_bytes, checksum_sha256)
VALUES ('invalid/v1/empty', NULL, NULL, 'application/octet-stream', 0, 'invalid-checksum')`); err == nil {
		t.Fatal("storage-location constraint accepted an object without a content source")
	}
	if err := executeEmbeddedMigration(ctx, connection, "2026100913_private_objects_external_storage.down.sql"); err == nil {
		t.Fatal("rollback accepted a MinIO-only object that has no PostgreSQL copy")
	}
	if _, err := connection.Exec(ctx, `
UPDATE private_objects
SET content = decode('040506', 'hex')
WHERE storage_key = 'minio/v1/external-only'`); err != nil {
		t.Fatalf("restore PostgreSQL copy for rollback: %v", err)
	}
	if err := executeEmbeddedMigration(ctx, connection, "2026100913_private_objects_external_storage.down.sql"); err != nil {
		t.Fatalf("roll back external storage expansion with complete PostgreSQL copies: %v", err)
	}
	var externalColumnCount int
	if err := connection.QueryRow(ctx, `
SELECT count(*)
FROM information_schema.columns
WHERE table_schema = current_schema()
  AND table_name = 'private_objects'
  AND column_name = 'external_storage_key'`).Scan(&externalColumnCount); err != nil {
		t.Fatalf("check external storage column after rollback: %v", err)
	}
	if externalColumnCount != 0 {
		t.Fatalf("external_storage_key columns after rollback = %d, want 0", externalColumnCount)
	}
}
