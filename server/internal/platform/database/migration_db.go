package database

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
)

// OpenPostgresMigrationDatabase opens the single database/sql connection used
// by the schema migration command.
func OpenPostgresMigrationDatabase(databaseURL string) (*sql.DB, error) {
	return OpenPostgresMigrationDatabaseWithContext(
		context.Background(),
		databaseURL,
		DefaultPostgresNativePoolConfig().PingTimeout,
	)
}

// OpenPostgresMigrationDatabaseWithContext opens and verifies a PostgreSQL
// database/sql handle for a one-shot migration process. The caller owns the
// returned handle and must close it after the migration completes.
func OpenPostgresMigrationDatabaseWithContext(
	ctx context.Context,
	databaseURL string,
	pingTimeout time.Duration,
) (*sql.DB, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if strings.TrimSpace(databaseURL) == "" {
		return nil, fmt.Errorf("database URL is required")
	}
	if pingTimeout <= 0 {
		return nil, fmt.Errorf("postgresql migration ping timeout must be positive")
	}

	sqlDatabase, err := sql.Open("pgx", NormalizePostgresURL(strings.TrimSpace(databaseURL)))
	if err != nil {
		return nil, fmt.Errorf("open postgresql migration database: %w", err)
	}
	sqlDatabase.SetMaxOpenConns(1)
	sqlDatabase.SetMaxIdleConns(1)

	pingContext, cancel := context.WithTimeout(ctx, pingTimeout)
	defer cancel()
	if err := sqlDatabase.PingContext(pingContext); err != nil {
		pingErr := fmt.Errorf("ping postgresql migration database: %w", err)
		if closeErr := sqlDatabase.Close(); closeErr != nil {
			return nil, errors.Join(
				pingErr,
				fmt.Errorf("close postgresql migration database after failed ping: %w", closeErr),
			)
		}
		return nil, pingErr
	}

	return sqlDatabase, nil
}
