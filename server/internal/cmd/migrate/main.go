package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/migrations"
	"github.com/golang-migrate/migrate/v4"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx); err != nil {
		slog.Error("migration command failed", "error", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		return errors.New("database url is required")
	}
	sqlDatabase, err := database.OpenPostgresMigrationDatabaseWithContext(
		ctx,
		databaseURL,
		database.PostgresNativePoolConfigFromEnv().PingTimeout,
	)
	if err != nil {
		return fmt.Errorf("open migration database: %w", err)
	}
	migrator, err := database.NewPostgresMigrator(
		migrations.FS,
		".",
		sqlDatabase,
		database.DefaultPostgresMigratorConfig(),
	)
	if err != nil {
		migratorErr := fmt.Errorf("create migrator: %w", err)
		if closeErr := sqlDatabase.Close(); closeErr != nil {
			return errors.Join(
				migratorErr,
				fmt.Errorf("close migration database: %w", closeErr),
			)
		}
		return migratorErr
	}
	migrationErr := migrator.Up()
	if errors.Is(migrationErr, migrate.ErrNoChange) {
		migrationErr = nil
	}
	sourceErr, databaseErr := migrator.Close()
	return errors.Join(migrationErr, sourceErr, databaseErr)
}
