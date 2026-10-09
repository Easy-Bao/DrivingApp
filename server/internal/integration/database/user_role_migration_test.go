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

func TestUserRoleCheckMigrationEnforcesSupportedRoles(t *testing.T) {
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

	schemaName := fmt.Sprintf("user_role_it_%d", time.Now().UnixNano())
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
	if _, err := connection.Exec(ctx, "CREATE TABLE users (id serial PRIMARY KEY, role text NOT NULL)"); err != nil {
		t.Fatalf("create legacy users table: %v", err)
	}
	if _, err := connection.Exec(ctx, "INSERT INTO users (role) VALUES ('passenger'), ('driver')"); err != nil {
		t.Fatalf("seed supported user roles: %v", err)
	}

	if err := executeEmbeddedMigration(ctx, connection, "2026100912_users_role_check.up.sql"); err != nil {
		t.Fatalf("apply user role check migration: %v", err)
	}
	if _, err := connection.Exec(ctx, "INSERT INTO users (role) VALUES ('driver')"); err != nil {
		t.Fatalf("insert supported user role: %v", err)
	}
	if _, err := connection.Exec(ctx, "INSERT INTO users (role) VALUES ('admin')"); err == nil {
		t.Fatal("user role constraint accepted an unsupported role")
	}

	if err := executeEmbeddedMigration(ctx, connection, "2026100912_users_role_check.down.sql"); err != nil {
		t.Fatalf("roll back user role check migration: %v", err)
	}
	if _, err := connection.Exec(ctx, "INSERT INTO users (role) VALUES ('admin')"); err != nil {
		t.Fatalf("rollback did not remove user role constraint: %v", err)
	}
}
