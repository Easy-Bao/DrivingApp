package migration

import (
	"context"
	"strings"
	"testing"

	"entgo.io/ent/dialect"
)

func TestMigrationPlanRejectsDuplicateOrUnorderedVersions(t *testing.T) {
	if err := validateMigrationPlan([]migration{
		{version: 2, name: "second", apply: func(context.Context, dialect.ExecQuerier) error { return nil }},
		{version: 1, name: "first", apply: func(context.Context, dialect.ExecQuerier) error { return nil }},
	}); err == nil {
		t.Fatal("expected unordered migrations to be rejected")
	}
	if err := validateMigrationPlan([]migration{
		{version: 1, name: "first", apply: func(context.Context, dialect.ExecQuerier) error { return nil }},
		{version: 1, name: "duplicate", apply: func(context.Context, dialect.ExecQuerier) error { return nil }},
	}); err == nil {
		t.Fatal("expected duplicate migration versions to be rejected")
	}
}

func TestIntegrityMigrationIncludesFinancialAndParticipantConstraints(t *testing.T) {
	joinedIndexes := strings.Join(indexStatements, "\n")
	for _, expected := range []string{
		"ride_passenger_id",
		"bidoffer_session_id_driver_id",
		"review_ride_id",
		"notification_user_id_created_at",
	} {
		if !strings.Contains(joinedIndexes, expected) {
			t.Fatalf("missing index %q", expected)
		}
	}
	joinedForeignKeys := strings.Join(foreignKeyStatements, "\n")
	for _, expected := range []string{
		"rides_passenger_fk",
		"ride_settlements_ride_fk",
		"driver_wallet_accounts_driver_fk",
		"driver_documents_driver_fk",
	} {
		if !strings.Contains(joinedForeignKeys, expected) {
			t.Fatalf("missing foreign key %q", expected)
		}
	}
}

func TestMigrationPlanEndsWithRefreshSessions(t *testing.T) {
	runner := NewRunner(nil)
	last := runner.migrations[len(runner.migrations)-1]
	if last.version != 2026082702 || last.name != "enforce_ride_state_constraints" {
		t.Fatalf("last migration = %d %q", last.version, last.name)
	}
}

func TestRideStateMigrationCanonicalizesAndConstrainsStatuses(t *testing.T) {
	joined := strings.Join(rideStateConstraintStatements, "\n")
	for _, expected := range []string{
		"UPDATE rides SET status = 'cancelled' WHERE status = 'canceled'",
		"rides_status_check",
		"rides_driver_assignment_check",
		"bid_sessions_status_check",
		"ride_settlements_payment_status_check",
		"VALIDATE CONSTRAINT rides_status_check",
	} {
		if !strings.Contains(joined, expected) {
			t.Fatalf("ride state migration is missing %q", expected)
		}
	}
}
