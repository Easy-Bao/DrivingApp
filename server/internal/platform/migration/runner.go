package migration

import (
	"context"
	"database/sql"
	"fmt"
	"sort"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	entmigrate "github.com/Easy-Bao/DrivingApp/server/ent/migrate"
)

const (
	migrationLockID = int64(6_617_401_202_608_23)
	defaultTimeout  = 5 * time.Minute
)

type migration struct {
	version int64
	name    string
	apply   func(context.Context, *sql.Conn) error
}

type Runner struct {
	database   *sql.DB
	migrations []migration
	timeout    time.Duration
}

func NewRunner(database *sql.DB, client *ent.Client) *Runner {
	schemaSync := func(ctx context.Context, _ *sql.Conn) error {
		if client == nil {
			return fmt.Errorf("migration schema client is required")
		}
		return client.Schema.Create(
			ctx,
			entmigrate.WithDropColumn(false),
			entmigrate.WithDropIndex(false),
			entmigrate.WithForeignKeys(true),
		)
	}
	refreshSessionSchema := func(ctx context.Context, connection *sql.Conn) error {
		if err := schemaSync(ctx, connection); err != nil {
			return err
		}
		return executeStatements(ctx, connection, []string{
			addForeignKey("refresh_sessions_user_fk", "refresh_sessions", "user_id", "users", "id", "CASCADE"),
			validateForeignKey("refresh_sessions", "refresh_sessions_user_fk"),
		})
	}
	return &Runner{
		database: database,
		timeout:  defaultTimeout,
		migrations: []migration{
			{
				version: 2026082301,
				name:    "synchronize_additive_ent_schema",
				apply:   schemaSync,
			},
			{
				version: 2026082302,
				name:    "backfill_financial_satellites",
				apply:   applyFinancialBackfill,
			},
			{
				version: 2026082303,
				name:    "enforce_relational_integrity",
				apply:   applyRelationalIntegrity,
			},
			{
				version: 2026082304,
				name:    "optimize_driver_reporting_indexes",
				apply:   applyReportingIndexes,
			},
			{
				version: 2026082305,
				name:    "secure_private_driver_documents",
				apply:   applyPrivateDocumentMetadata,
			},
			{
				version: 2026082601,
				name:    "add_passenger_profile_attributes",
				apply:   applyPassengerProfileAttributes,
			},
			{
				version: 2026082701,
				name:    "add_refresh_sessions",
				apply:   refreshSessionSchema,
			},
			{
				version: 2026082702,
				name:    "enforce_ride_state_constraints",
				apply:   applyRideStateConstraints,
			},
		},
	}
}

func (runner *Runner) Run(ctx context.Context) error {
	if runner.database == nil {
		return fmt.Errorf("migration database is required")
	}
	if err := validateMigrationPlan(runner.migrations); err != nil {
		return err
	}
	if _, hasDeadline := ctx.Deadline(); !hasDeadline {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, runner.timeout)
		defer cancel()
	}

	connection, err := runner.database.Conn(ctx)
	if err != nil {
		return fmt.Errorf("reserve migration connection: %w", err)
	}
	defer connection.Close()

	if _, err := connection.ExecContext(
		ctx,
		"SELECT pg_advisory_lock($1)",
		migrationLockID,
	); err != nil {
		return fmt.Errorf("acquire migration lock: %w", err)
	}
	defer releaseMigrationLock(connection)

	if _, err := connection.ExecContext(ctx, `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version BIGINT PRIMARY KEY,
			name TEXT NOT NULL,
			applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
		)`); err != nil {
		return fmt.Errorf("create migration ledger: %w", err)
	}
	if err := ValidateCompatibleSchema(ctx, connection); err != nil {
		return err
	}
	if err := expireStaleBidSessions(ctx, connection); err != nil {
		return err
	}

	for _, item := range runner.migrations {
		var applied bool
		if err := connection.QueryRowContext(
			ctx,
			"SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = $1)",
			item.version,
		).Scan(&applied); err != nil {
			return fmt.Errorf("read migration %d state: %w", item.version, err)
		}
		if applied {
			continue
		}
		if err := item.apply(ctx, connection); err != nil {
			return fmt.Errorf("apply migration %d (%s): %w", item.version, item.name, err)
		}
		if _, err := connection.ExecContext(
			ctx,
			"INSERT INTO schema_migrations (version, name) VALUES ($1, $2)",
			item.version,
			item.name,
		); err != nil {
			return fmt.Errorf("record migration %d: %w", item.version, err)
		}
	}
	return nil
}

func validateMigrationPlan(items []migration) error {
	if len(items) == 0 {
		return fmt.Errorf("migration plan is empty")
	}
	versions := make([]int64, 0, len(items))
	seen := make(map[int64]struct{}, len(items))
	for _, item := range items {
		if item.version <= 0 || item.name == "" || item.apply == nil {
			return fmt.Errorf("invalid migration definition: version=%d name=%q", item.version, item.name)
		}
		if _, exists := seen[item.version]; exists {
			return fmt.Errorf("duplicate migration version %d", item.version)
		}
		seen[item.version] = struct{}{}
		versions = append(versions, item.version)
	}
	if !sort.SliceIsSorted(versions, func(i, j int) bool { return versions[i] < versions[j] }) {
		return fmt.Errorf("migrations must be ordered by version")
	}
	return nil
}

func releaseMigrationLock(connection *sql.Conn) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, _ = connection.ExecContext(ctx, "SELECT pg_advisory_unlock($1)", migrationLockID)
}
