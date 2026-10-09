package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	miniostorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/minio"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx); err != nil {
		slog.Error("object storage migration failed", "error", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	databaseURL := strings.TrimSpace(os.Getenv("DATABASE_URL"))
	if databaseURL == "" {
		return errors.New("database URL is required")
	}
	config, err := miniostorage.ConfigFromEnv(os.Getenv)
	if err != nil {
		return fmt.Errorf("load MinIO configuration: %w", err)
	}
	pool, err := database.OpenPostgresPoolWithContext(
		ctx,
		databaseURL,
		database.PostgresNativePoolConfigFrom(os.Getenv),
	)
	if err != nil {
		return fmt.Errorf("open PostgreSQL pool: %w", err)
	}
	defer pool.Close()

	store, err := miniostorage.NewObjectStore(ctx, pool, config)
	if err != nil {
		return fmt.Errorf("create MinIO object store: %w", err)
	}
	migrated, err := store.MigrateLegacyObjects(ctx)
	if err != nil {
		return fmt.Errorf("copy PostgreSQL objects to MinIO: %w", err)
	}
	slog.InfoContext(ctx, "copied PostgreSQL objects to MinIO", "object_count", migrated)
	return nil
}
