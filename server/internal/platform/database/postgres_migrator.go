package database

import (
	"database/sql"
	"errors"
	"fmt"
	"io/fs"
	"strings"
	"time"

	"github.com/golang-migrate/migrate/v4"
	pgxmigrate "github.com/golang-migrate/migrate/v4/database/pgx/v5"
	"github.com/golang-migrate/migrate/v4/source/iofs"
)

const (
	_postgresMigrationSourceName = "iofs"
	_postgresMigrationDriverName = "pgx5"
	_defaultMigrationTimeout     = 5 * time.Minute
)

// PostgresMigratorConfig controls the PostgreSQL migration driver.
type PostgresMigratorConfig struct {
	MigrationsTable       string
	DatabaseName          string
	SchemaName            string
	StatementTimeout      time.Duration
	MultiStatementEnabled bool
	MultiStatementMaxSize int
}

type PostgresMigratorDependencies struct {
	Migrations    fs.FS
	MigrationPath string
	Database      *sql.DB
	Config        PostgresMigratorConfig
}

func DefaultPostgresMigratorConfig() PostgresMigratorConfig {
	return PostgresMigratorConfig{
		MigrationsTable:       "app_schema_migrations",
		StatementTimeout:      _defaultMigrationTimeout,
		MultiStatementMaxSize: 10 * 1 << 20,
	}
}

// NewPostgresMigrator connects embedded migration files to the official
// PostgreSQL migration driver. Ownership of database transfers to the returned
// migrator; callers must close the migrator and must not reuse database after
// that close.
func NewPostgresMigrator(dependencies PostgresMigratorDependencies) (*migrate.Migrate, error) {
	if dependencies.Migrations == nil {
		return nil, fmt.Errorf("migration filesystem is required")
	}
	if !fs.ValidPath(dependencies.MigrationPath) {
		return nil, fmt.Errorf("migration path must be a valid relative path")
	}
	if dependencies.Database == nil {
		return nil, fmt.Errorf("migration database is required")
	}
	if err := dependencies.Config.validate(); err != nil {
		return nil, err
	}

	sourceDriver, err := iofs.New(dependencies.Migrations, dependencies.MigrationPath)
	if err != nil {
		return nil, fmt.Errorf("open migration source: %w", err)
	}

	databaseDriver, err := pgxmigrate.WithInstance(dependencies.Database, &pgxmigrate.Config{
		MigrationsTable:       dependencies.Config.MigrationsTable,
		DatabaseName:          dependencies.Config.DatabaseName,
		SchemaName:            dependencies.Config.SchemaName,
		StatementTimeout:      dependencies.Config.StatementTimeout,
		MultiStatementEnabled: dependencies.Config.MultiStatementEnabled,
		MultiStatementMaxSize: dependencies.Config.MultiStatementMaxSize,
	})
	if err != nil {
		return nil, errors.Join(
			fmt.Errorf("open migration database driver: %w", err),
			sourceDriver.Close(),
		)
	}

	migrator, err := migrate.NewWithInstance(
		_postgresMigrationSourceName,
		sourceDriver,
		_postgresMigrationDriverName,
		databaseDriver,
	)
	if err != nil {
		return nil, errors.Join(
			fmt.Errorf("create postgres migrator: %w", err),
			databaseDriver.Close(),
			sourceDriver.Close(),
		)
	}
	return migrator, nil
}

func (config PostgresMigratorConfig) validate() error {
	if strings.TrimSpace(config.MigrationsTable) == "" {
		return fmt.Errorf("migration table is required")
	}
	if config.StatementTimeout < 0 {
		return fmt.Errorf("migration statement timeout cannot be negative")
	}
	if config.MultiStatementMaxSize <= 0 {
		return fmt.Errorf("migration multi-statement max size must be positive")
	}
	return nil
}
