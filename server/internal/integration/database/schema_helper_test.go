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

func requireIntegrationDatabaseURL(t *testing.T, envKeys ...string) string {
	t.Helper()
	if len(envKeys) == 0 {
		envKeys = []string{"TEST_DATABASE_URL"}
	}
	for _, key := range envKeys {
		if value := os.Getenv(key); value != "" {
			return value
		}
	}
	t.Skipf("%s is not set", envKeys[0])
	return ""
}

func openIsolatedSchemaConn(
	t *testing.T,
	ctx context.Context,
	prefix string,
	envKeys ...string,
) *pgx.Conn {
	t.Helper()
	databaseURL := requireIntegrationDatabaseURL(t, envKeys...)

	admin, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatalf("connect to test PostgreSQL database: %v", err)
	}

	schemaName := fmt.Sprintf("%s_%d", prefix, time.Now().UnixNano())
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
	return connection
}
