package migration

import (
	"context"
	"fmt"
	"sort"
	"time"

	"entgo.io/ent/dialect"
	entsql "entgo.io/ent/dialect/sql"
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
	apply   func(context.Context, dialect.ExecQuerier) error
}

type Runner struct {
	driver     dialect.Driver
	migrations []migration
	timeout    time.Duration
}

func NewRunner(driver dialect.Driver) *Runner {
	dialectName := dialect.Postgres
	if driver != nil {
		dialectName = driver.Dialect()
	}
	schemaSync := func(ctx context.Context, executor dialect.ExecQuerier) error {
		migrationClient := ent.NewClient(ent.Driver(&migrationDriver{
			executor:    executor,
			dialectName: dialectName,
		}))
		return migrationClient.Schema.Create(
			ctx,
			entmigrate.WithDropColumn(false),
			entmigrate.WithDropIndex(false),
			entmigrate.WithForeignKeys(true),
		)
	}
	refreshSessionSchema := func(ctx context.Context, executor dialect.ExecQuerier) error {
		if err := schemaSync(ctx, executor); err != nil {
			return err
		}
		return executeStatements(ctx, executor, []string{
			addForeignKey("refresh_sessions_user_fk", "refresh_sessions", "user_id", "users", "id", "CASCADE"),
			validateForeignKey("refresh_sessions", "refresh_sessions_user_fk"),
		})
	}
	return &Runner{
		driver:  driver,
		timeout: defaultTimeout,
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
	if runner.driver == nil {
		return fmt.Errorf("migration driver is required")
	}
	if err := validateMigrationPlan(runner.migrations); err != nil {
		return err
	}
	if _, hasDeadline := ctx.Deadline(); !hasDeadline {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, runner.timeout)
		defer cancel()
	}

	transaction, err := runner.driver.Tx(ctx)
	if err != nil {
		return fmt.Errorf("begin migration transaction: %w", err)
	}
	defer transaction.Rollback()

	if err := transaction.Exec(
		ctx,
		"SELECT pg_advisory_xact_lock($1)",
		[]any{migrationLockID},
		nil,
	); err != nil {
		return fmt.Errorf("acquire migration lock: %w", err)
	}

	if err := transaction.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version BIGINT PRIMARY KEY,
			name TEXT NOT NULL,
			applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
		)`, []any{}, nil); err != nil {
		return fmt.Errorf("create migration ledger: %w", err)
	}
	if err := ValidateCompatibleSchema(ctx, transaction); err != nil {
		return err
	}
	if err := expireStaleBidSessions(ctx, transaction); err != nil {
		return err
	}

	for _, item := range runner.migrations {
		applied, err := migrationApplied(ctx, transaction, item.version)
		if err != nil {
			return fmt.Errorf("read migration %d state: %w", item.version, err)
		}
		if applied {
			continue
		}
		if err := item.apply(ctx, transaction); err != nil {
			return fmt.Errorf("apply migration %d (%s): %w", item.version, item.name, err)
		}
		if err := transaction.Exec(
			ctx,
			"INSERT INTO schema_migrations (version, name) VALUES ($1, $2)",
			[]any{item.version, item.name},
			nil,
		); err != nil {
			return fmt.Errorf("record migration %d: %w", item.version, err)
		}
	}
	if err := transaction.Commit(); err != nil {
		return fmt.Errorf("commit migrations: %w", err)
	}
	return nil
}

type migrationDriver struct {
	executor    dialect.ExecQuerier
	dialectName string
}

func (driver *migrationDriver) Exec(ctx context.Context, query string, args, result any) error {
	return driver.executor.Exec(ctx, query, args, result)
}

func (driver *migrationDriver) Query(ctx context.Context, query string, args, result any) error {
	return driver.executor.Query(ctx, query, args, result)
}

// Tx returns a no-op nested transaction so Ent schema migration statements stay
// inside the runner's already-open transaction.
func (driver *migrationDriver) Tx(context.Context) (dialect.Tx, error) {
	return dialect.NopTx(driver), nil
}

func (*migrationDriver) Close() error { return nil }

func (driver *migrationDriver) Dialect() string { return driver.dialectName }

func migrationApplied(ctx context.Context, executor dialect.ExecQuerier, version int64) (bool, error) {
	rows := &entsql.Rows{}
	if err := executor.Query(
		ctx,
		"SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = $1)",
		[]any{version},
		rows,
	); err != nil {
		return false, err
	}
	defer rows.Close()
	return entsql.ScanBool(rows)
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
