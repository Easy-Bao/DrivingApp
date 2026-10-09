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

func TestCoreEntityTimestampMigrationTracksMutableRows(t *testing.T) {
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

	schemaName := fmt.Sprintf("core_timestamps_it_%d", time.Now().UnixNano())
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
CREATE TABLE users (id bigint PRIMARY KEY);
CREATE TABLE driver_profiles (id bigint PRIMARY KEY);
CREATE TABLE passenger_profiles (id bigint PRIMARY KEY);
CREATE TABLE driver_wallet_accounts (
    id bigint PRIMARY KEY,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users (id) VALUES (1);
INSERT INTO driver_profiles (id) VALUES (1);
INSERT INTO passenger_profiles (id) VALUES (1);
INSERT INTO driver_wallet_accounts (id, updated_at)
VALUES (1, '2020-01-01T00:00:00Z');`)
	if err != nil {
		t.Fatalf("create and seed core tables: %v", err)
	}

	if err := executeEmbeddedMigration(ctx, connection, "2026100914_core_entity_timestamps.up.sql"); err != nil {
		t.Fatalf("apply core timestamp migration: %v", err)
	}

	for _, table := range []string{"users", "driver_profiles", "passenger_profiles"} {
		var createdAt, updatedAt time.Time
		query := "SELECT created_at, updated_at FROM " + pgx.Identifier{table}.Sanitize() + " WHERE id = 1"
		if err := connection.QueryRow(ctx, query).Scan(&createdAt, &updatedAt); err != nil {
			t.Fatalf("read migrated timestamps from %s: %v", table, err)
		}
		if createdAt.IsZero() || updatedAt.IsZero() || !createdAt.Equal(updatedAt) {
			t.Fatalf("%s migrated timestamps = created %v, updated %v; want the same nonzero backfill time", table, createdAt, updatedAt)
		}
	}

	var walletCreatedAt, walletUpdatedAt time.Time
	if err := connection.QueryRow(ctx, `
SELECT created_at, updated_at
FROM driver_wallet_accounts
WHERE id = 1`).Scan(&walletCreatedAt, &walletUpdatedAt); err != nil {
		t.Fatalf("read migrated wallet timestamps: %v", err)
	}
	if walletCreatedAt.IsZero() || walletUpdatedAt.Year() != 2020 {
		t.Fatalf("wallet timestamps = created %v, updated %v; want a populated creation time and preserved update time", walletCreatedAt, walletUpdatedAt)
	}

	if _, err := connection.Exec(ctx, `
UPDATE users
SET updated_at = created_at + interval '1 second'
WHERE id = 1`); err != nil {
		t.Fatalf("record a post-migration update: %v", err)
	}
	if err := executeEmbeddedMigration(ctx, connection, "2026100914_core_entity_timestamps.down.sql"); err == nil {
		t.Fatal("rollback removed timestamps after a post-migration update")
	}
	if _, err := connection.Exec(ctx, `
UPDATE users
SET updated_at = created_at
WHERE id = 1`); err != nil {
		t.Fatalf("restore the timestamp row for rollback: %v", err)
	}

	transaction, err := connection.Begin(ctx)
	if err != nil {
		t.Fatalf("begin wallet creation and credit: %v", err)
	}
	if _, err := transaction.Exec(ctx, `
INSERT INTO driver_wallet_accounts (id)
VALUES (2);
UPDATE driver_wallet_accounts
SET updated_at = GREATEST(CURRENT_TIMESTAMP, created_at + interval '1 microsecond')
WHERE id = 2`); err != nil {
		_ = transaction.Rollback(ctx)
		t.Fatalf("create and credit a wallet in one transaction: %v", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatalf("commit wallet creation and credit: %v", err)
	}
	if err := executeEmbeddedMigration(ctx, connection, "2026100914_core_entity_timestamps.down.sql"); err == nil {
		t.Fatal("rollback removed timestamps after a wallet was created and credited in one transaction")
	}
	if _, err := connection.Exec(ctx, `DELETE FROM driver_wallet_accounts WHERE id = 2`); err != nil {
		t.Fatalf("remove the wallet row before rollback: %v", err)
	}
	if err := executeEmbeddedMigration(ctx, connection, "2026100914_core_entity_timestamps.down.sql"); err != nil {
		t.Fatalf("roll back unused timestamp columns: %v", err)
	}

	var addedColumnCount int
	if err := connection.QueryRow(ctx, `
SELECT count(*)
FROM information_schema.columns
WHERE table_schema = current_schema()
  AND ((table_name IN ('users', 'driver_profiles', 'passenger_profiles')
        AND column_name IN ('created_at', 'updated_at'))
    OR (table_name = 'driver_wallet_accounts' AND column_name = 'created_at'))`).Scan(&addedColumnCount); err != nil {
		t.Fatalf("check timestamp columns after rollback: %v", err)
	}
	if addedColumnCount != 0 {
		t.Fatalf("timestamp columns remaining after rollback = %d, want 0", addedColumnCount)
	}
}
