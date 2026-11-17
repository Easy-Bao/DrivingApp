//go:build integration

package database_test

import (
	"context"
	"testing"
	"time"
)

func TestUserRoleCheckMigrationEnforcesSupportedRoles(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	connection := openIsolatedSchemaConn(t, ctx, "user_role_it")
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
