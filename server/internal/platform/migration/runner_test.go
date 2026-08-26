package migration

import (
	"context"
	"database/sql"
	"strings"
	"testing"
)

func TestMigrationPlanRejectsDuplicateOrUnorderedVersions(t *testing.T) {
	if err := validateMigrationPlan([]migration{
		{version: 2, name: "second", apply: func(context.Context, *sql.Conn) error { return nil }},
		{version: 1, name: "first", apply: func(context.Context, *sql.Conn) error { return nil }},
	}); err == nil {
		t.Fatal("expected unordered migrations to be rejected")
	}
	if err := validateMigrationPlan([]migration{
		{version: 1, name: "first", apply: func(context.Context, *sql.Conn) error { return nil }},
		{version: 1, name: "duplicate", apply: func(context.Context, *sql.Conn) error { return nil }},
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

func TestMigrationPlanEndsWithPassengerProfileAttributes(t *testing.T) {
	runner := NewRunner(nil, nil)
	last := runner.migrations[len(runner.migrations)-1]
	if last.version != 2026082601 || last.name != "add_passenger_profile_attributes" {
		t.Fatalf("last migration = %d %q", last.version, last.name)
	}
}
