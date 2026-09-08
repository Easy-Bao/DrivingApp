package main

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	dbmigrations "github.com/Easy-Bao/DrivingApp/server/db/migrations"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
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
		return err
	}
	migrator, err := platformmigration.NewPostgresMigrator(
		dbmigrations.FS,
		".",
		sqlDatabase,
		platformmigration.DefaultPostgresMigratorConfig(),
	)
	if err != nil {
		_ = sqlDatabase.Close()
		return err
	}
	migrationErr := migrator.Up()
	if errors.Is(migrationErr, migrate.ErrNoChange) {
		migrationErr = nil
	}
	sourceErr, databaseErr := migrator.Close()
	return errors.Join(migrationErr, sourceErr, databaseErr)
}
