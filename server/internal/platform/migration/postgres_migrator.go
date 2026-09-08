package migration

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
	postgresMigrationSourceName = "iofs"
	postgresMigrationDriverName = "pgx5"
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

func DefaultPostgresMigratorConfig() PostgresMigratorConfig {
	return PostgresMigratorConfig{
		MigrationsTable:       "app_schema_migrations",
		StatementTimeout:      defaultTimeout,
		MultiStatementMaxSize: 10 * 1 << 20,
	}
}

// NewPostgresMigrator connects embedded migration files to the official
// PostgreSQL migration driver. Ownership of database transfers to the returned
// migrator; callers must close the migrator and must not reuse database after
// that close.
func NewPostgresMigrator(
	migrations fs.FS,
	migrationPath string,
	database *sql.DB,
	config PostgresMigratorConfig,
) (*migrate.Migrate, error) {
	if migrations == nil {
		return nil, fmt.Errorf("migration filesystem is required")
	}
	if !fs.ValidPath(migrationPath) {
		return nil, fmt.Errorf("migration path must be a valid relative path")
	}
	if database == nil {
		return nil, fmt.Errorf("migration database is required")
	}
	if err := config.validate(); err != nil {
		return nil, err
	}

	sourceDriver, err := iofs.New(migrations, migrationPath)
	if err != nil {
		return nil, fmt.Errorf("open migration source: %w", err)
	}

	databaseDriver, err := pgxmigrate.WithInstance(database, &pgxmigrate.Config{
		MigrationsTable:       config.MigrationsTable,
		DatabaseName:          config.DatabaseName,
		SchemaName:            config.SchemaName,
		StatementTimeout:      config.StatementTimeout,
		MultiStatementEnabled: config.MultiStatementEnabled,
		MultiStatementMaxSize: config.MultiStatementMaxSize,
	})
	if err != nil {
		return nil, errors.Join(
			fmt.Errorf("open migration database driver: %w", err),
			sourceDriver.Close(),
		)
	}

	migrator, err := migrate.NewWithInstance(
		postgresMigrationSourceName,
		sourceDriver,
		postgresMigrationDriverName,
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
