package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	serverconfig "github.com/Easy-Bao/DrivingApp/server/internal/config"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/migrations"
	miniostorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/minio"
	"github.com/golang-migrate/migrate/v4"
)

const (
	_externalVerificationVersion uint = 2026100915
	_contentContractionVersion   uint = 2026100916
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx); err != nil {
		slog.Error("object storage migration failed", "error", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) (runErr error) {
	config, err := serverconfig.LoadObjectStorageMigration()
	if err != nil {
		return fmt.Errorf("load object storage migration configuration: %w", err)
	}
	migrationDatabase, err := database.OpenPostgresMigrationDatabaseWithContext(
		ctx,
		config.DatabaseURL,
		config.PostgresPool.PingTimeout,
	)
	if err != nil {
		return fmt.Errorf("open migration database: %w", err)
	}
	migrator, err := database.NewPostgresMigrator(database.PostgresMigratorDependencies{
		Migrations:    migrations.FS,
		MigrationPath: ".",
		Database:      migrationDatabase,
		Config:        database.DefaultPostgresMigratorConfig(),
	})
	if err != nil {
		if closeErr := migrationDatabase.Close(); closeErr != nil {
			return errors.Join(fmt.Errorf("create migrator: %w", err), closeErr)
		}
		return fmt.Errorf("create migrator: %w", err)
	}
	defer func() {
		sourceErr, databaseErr := migrator.Close()
		runErr = errors.Join(runErr, sourceErr, databaseErr)
	}()
	if err := migrateUpTo(migrator, _externalVerificationVersion); err != nil {
		return fmt.Errorf("apply private object verification schema: %w", err)
	}

	pool, err := database.OpenPostgresPoolWithContext(
		ctx,
		config.DatabaseURL,
		config.PostgresPool,
	)
	if err != nil {
		return fmt.Errorf("open PostgreSQL pool: %w", err)
	}
	defer pool.Close()
	store, err := miniostorage.NewObjectStore(ctx, pool, config.MinIO)
	if err != nil {
		return fmt.Errorf("create MinIO object store: %w", err)
	}
	migrated, err := store.MigrateLegacyObjects(ctx)
	if err != nil {
		return fmt.Errorf("copy PostgreSQL objects to MinIO: %w", err)
	}
	verified, err := store.VerifyExternalObjects(ctx)
	if err != nil {
		return fmt.Errorf("verify MinIO objects: %w", err)
	}
	if err := migrateUpTo(migrator, _contentContractionVersion); err != nil {
		return fmt.Errorf("contract PostgreSQL private object storage: %w", err)
	}
	slog.InfoContext(ctx, "copied and verified private objects in MinIO", "migrated_count", migrated, "verified_count", verified)
	return nil
}

func migrateUpTo(migrator *migrate.Migrate, target uint) error {
	version, dirty, err := migrator.Version()
	if errors.Is(err, migrate.ErrNilVersion) {
		version = 0
		err = nil
	}
	if err != nil {
		return fmt.Errorf("read current migration version: %w", err)
	}
	if dirty {
		return fmt.Errorf("database migration version %d is dirty", version)
	}
	if version >= target {
		return nil
	}
	if err := migrator.Migrate(target); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		return err
	}
	return nil
}
