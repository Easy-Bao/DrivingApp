package migration

import (
	"context"
	"fmt"

	"entgo.io/ent/dialect"
	entsql "entgo.io/ent/dialect/sql"
)

func expireStaleBidSessions(ctx context.Context, connection dialect.ExecQuerier) error {
	rows := &entsql.Rows{}
	if err := connection.Query(
		ctx,
		"SELECT to_regclass('public.bid_sessions') IS NOT NULL",
		[]any{},
		rows,
	); err != nil {
		return fmt.Errorf("inspect bid session table: %w", err)
	}
	exists, err := entsql.ScanBool(rows)
	_ = rows.Close()
	if err != nil {
		return fmt.Errorf("inspect bid session table: %w", err)
	}
	if !exists {
		return nil
	}
	if err := connection.Exec(ctx, `
		UPDATE bid_sessions
		SET status = 'expired'
		WHERE status = 'open' AND expires_at <= CURRENT_TIMESTAMP`, []any{}, nil); err != nil {
		return fmt.Errorf("expire stale bid sessions: %w", err)
	}
	return nil
}

func applyFinancialBackfill(ctx context.Context, connection dialect.ExecQuerier) error {
	statements := []string{
		`INSERT INTO driver_wallet_accounts (
			driver_id, balance_centavos, version, updated_at
		)
		SELECT user_id, wallet_balance_centavos, 0, CURRENT_TIMESTAMP
		FROM driver_profiles
		ON CONFLICT (driver_id) DO NOTHING`,
		`INSERT INTO ride_settlements (
			ride_id,
			gross_fare_centavos,
			commission_bps,
			commission_centavos,
			driver_payout_centavos,
			payment_status,
			cash_received_at,
			settled_at,
			created_at,
			updated_at
		)
		SELECT
			id,
			fare_centavos,
			commission_bps,
			commission_centavos,
			driver_payout_centavos,
			payment_status,
			cash_received_at,
			cash_received_at,
			created_at,
			CURRENT_TIMESTAMP
		FROM rides
		ON CONFLICT (ride_id) DO NOTHING`,
	}
	return executeStatements(ctx, connection, statements)
}

func applyRelationalIntegrity(ctx context.Context, connection dialect.ExecQuerier) error {
	if err := executeStatements(ctx, connection, indexStatements); err != nil {
		return err
	}
	if err := executeStatements(ctx, connection, foreignKeyStatements); err != nil {
		return err
	}
	return executeStatements(ctx, connection, validationStatements)
}

func applyReportingIndexes(ctx context.Context, connection dialect.ExecQuerier) error {
	return executeStatements(ctx, connection, []string{
		`CREATE INDEX IF NOT EXISTS ride_driver_id_status_completed_at ON rides (driver_id, status, completed_at)`,
		`CREATE INDEX IF NOT EXISTS ride_passenger_id_status_completed_at ON rides (passenger_id, status, completed_at)`,
		`DROP INDEX IF EXISTS ride_driver_id_status`,
	})
}

func executeStatements(ctx context.Context, connection dialect.ExecQuerier, statements []string) error {
	for index, statement := range statements {
		if err := connection.Exec(ctx, statement, []any{}, nil); err != nil {
			return fmt.Errorf("statement %d failed: %w", index+1, err)
		}
	}
	return nil
}

var indexStatements = []string{
	`CREATE UNIQUE INDEX IF NOT EXISTS passengerprofile_user_id ON passenger_profiles (user_id)`,
	`CREATE UNIQUE INDEX IF NOT EXISTS driverprofile_user_id ON driver_profiles (user_id)`,
	`CREATE UNIQUE INDEX IF NOT EXISTS driverwalletaccount_driver_id ON driver_wallet_accounts (driver_id)`,
	`CREATE UNIQUE INDEX IF NOT EXISTS ridesettlement_ride_id ON ride_settlements (ride_id)`,
	`CREATE INDEX IF NOT EXISTS ride_passenger_id_created_at ON rides (passenger_id, created_at)`,
	`CREATE INDEX IF NOT EXISTS ride_driver_id_created_at ON rides (driver_id, created_at)`,
	`CREATE INDEX IF NOT EXISTS ride_driver_id_status ON rides (driver_id, status)`,
	`CREATE UNIQUE INDEX IF NOT EXISTS ride_passenger_id ON rides (passenger_id)
		WHERE status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit')`,
	`CREATE INDEX IF NOT EXISTS bidsession_expires_at_created_at ON bid_sessions (expires_at, created_at)`,
	`CREATE INDEX IF NOT EXISTS bidsession_target_driver_id_created_at ON bid_sessions (target_driver_id, created_at)`,
	`CREATE UNIQUE INDEX IF NOT EXISTS bidsession_passenger_id ON bid_sessions (passenger_id)
		WHERE status = 'open'`,
	`CREATE INDEX IF NOT EXISTS bidoffer_session_id_created_at ON bid_offers (session_id, created_at)`,
	`CREATE UNIQUE INDEX IF NOT EXISTS bidoffer_session_id_driver_id ON bid_offers (session_id, driver_id)
		WHERE status = 'pending'`,
	`CREATE UNIQUE INDEX IF NOT EXISTS bid_ride_id_driver_id ON bids (ride_id, driver_id)
		WHERE status = 'pending'`,
	`CREATE UNIQUE INDEX IF NOT EXISTS review_ride_id ON reviews (ride_id) WHERE ride_id IS NOT NULL`,
	`CREATE INDEX IF NOT EXISTS review_driver_id_created_at ON reviews (driver_id, created_at)`,
	`CREATE INDEX IF NOT EXISTS passengerreview_passenger_id_created_at ON passenger_reviews (passenger_id, created_at)`,
	`CREATE INDEX IF NOT EXISTS notification_user_id_created_at ON notifications (user_id, created_at)`,
	`CREATE INDEX IF NOT EXISTS driverdocument_driver_id_document_type ON driver_documents (driver_id, document_type)`,
	`CREATE INDEX IF NOT EXISTS wallet_ledger_driver_created_idx ON wallet_ledgers (driver_id, created_at)`,
	`CREATE INDEX IF NOT EXISTS auditevent_actor_id_created_at ON audit_events (actor_id, created_at)`,
}

var foreignKeyStatements = []string{
	addForeignKey("passenger_profiles_user_fk", "passenger_profiles", "user_id", "users", "id", "CASCADE"),
	addForeignKey("driver_profiles_user_fk", "driver_profiles", "user_id", "users", "id", "CASCADE"),
	addForeignKey("driver_wallet_accounts_driver_fk", "driver_wallet_accounts", "driver_id", "users", "id", "RESTRICT"),
	addForeignKey("rides_passenger_fk", "rides", "passenger_id", "users", "id", "RESTRICT"),
	addForeignKey("rides_driver_fk", "rides", "driver_id", "users", "id", "RESTRICT"),
	addForeignKey("ride_settlements_ride_fk", "ride_settlements", "ride_id", "rides", "id", "RESTRICT"),
	addForeignKey("bid_sessions_passenger_fk", "bid_sessions", "passenger_id", "users", "id", "RESTRICT"),
	addForeignKey("bid_sessions_target_driver_fk", "bid_sessions", "target_driver_id", "users", "id", "RESTRICT"),
	addForeignKey("bid_sessions_accepted_driver_fk", "bid_sessions", "accepted_driver_id", "users", "id", "RESTRICT"),
	addForeignKey("bid_offers_session_fk", "bid_offers", "session_id", "bid_sessions", "id", "CASCADE"),
	addForeignKey("bid_offers_driver_fk", "bid_offers", "driver_id", "users", "id", "RESTRICT"),
	addForeignKey("bids_ride_fk", "bids", "ride_id", "rides", "id", "CASCADE"),
	addForeignKey("bids_driver_fk", "bids", "driver_id", "users", "id", "RESTRICT"),
	addForeignKey("reviews_ride_fk", "reviews", "ride_id", "rides", "id", "CASCADE"),
	addForeignKey("reviews_driver_fk", "reviews", "driver_id", "users", "id", "RESTRICT"),
	addForeignKey("reviews_passenger_fk", "reviews", "passenger_id", "users", "id", "RESTRICT"),
	addForeignKey("passenger_reviews_ride_fk", "passenger_reviews", "ride_id", "rides", "id", "CASCADE"),
	addForeignKey("passenger_reviews_driver_fk", "passenger_reviews", "driver_id", "users", "id", "RESTRICT"),
	addForeignKey("passenger_reviews_passenger_fk", "passenger_reviews", "passenger_id", "users", "id", "RESTRICT"),
	addForeignKey("notifications_user_fk", "notifications", "user_id", "users", "id", "CASCADE"),
	addForeignKey("driver_documents_driver_fk", "driver_documents", "driver_id", "users", "id", "RESTRICT"),
	addForeignKey("wallet_ledgers_driver_fk", "wallet_ledgers", "driver_id", "users", "id", "RESTRICT"),
	addForeignKey("wallet_ledgers_ride_fk", "wallet_ledgers", "ride_id", "rides", "id", "RESTRICT"),
	addForeignKey("audit_events_actor_fk", "audit_events", "actor_id", "users", "id", "RESTRICT"),
}

var validationStatements = []string{
	validateForeignKey("passenger_profiles", "passenger_profiles_user_fk"),
	validateForeignKey("driver_profiles", "driver_profiles_user_fk"),
	validateForeignKey("driver_wallet_accounts", "driver_wallet_accounts_driver_fk"),
	validateForeignKey("rides", "rides_passenger_fk"),
	validateForeignKey("rides", "rides_driver_fk"),
	validateForeignKey("ride_settlements", "ride_settlements_ride_fk"),
	validateForeignKey("bid_sessions", "bid_sessions_passenger_fk"),
	validateForeignKey("bid_sessions", "bid_sessions_target_driver_fk"),
	validateForeignKey("bid_sessions", "bid_sessions_accepted_driver_fk"),
	validateForeignKey("bid_offers", "bid_offers_session_fk"),
	validateForeignKey("bid_offers", "bid_offers_driver_fk"),
	validateForeignKey("bids", "bids_ride_fk"),
	validateForeignKey("bids", "bids_driver_fk"),
	validateForeignKey("reviews", "reviews_ride_fk"),
	validateForeignKey("reviews", "reviews_driver_fk"),
	validateForeignKey("reviews", "reviews_passenger_fk"),
	validateForeignKey("passenger_reviews", "passenger_reviews_ride_fk"),
	validateForeignKey("passenger_reviews", "passenger_reviews_driver_fk"),
	validateForeignKey("passenger_reviews", "passenger_reviews_passenger_fk"),
	validateForeignKey("notifications", "notifications_user_fk"),
	validateForeignKey("driver_documents", "driver_documents_driver_fk"),
	validateForeignKey("wallet_ledgers", "wallet_ledgers_driver_fk"),
	validateForeignKey("wallet_ledgers", "wallet_ledgers_ride_fk"),
	validateForeignKey("audit_events", "audit_events_actor_fk"),
}

func addForeignKey(
	name, table, column, referencedTable, referencedColumn, onDelete string,
) string {
	return fmt.Sprintf(`DO $migration$
	BEGIN
		IF NOT EXISTS (
			SELECT 1 FROM pg_constraint WHERE conname = '%s'
		) THEN
			ALTER TABLE %s
				ADD CONSTRAINT %s
				FOREIGN KEY (%s) REFERENCES %s (%s)
				ON DELETE %s NOT VALID;
		END IF;
	END
	$migration$`, name, table, name, column, referencedTable, referencedColumn, onDelete)
}

func validateForeignKey(table, name string) string {
	return fmt.Sprintf("ALTER TABLE %s VALIDATE CONSTRAINT %s", table, name)
}
