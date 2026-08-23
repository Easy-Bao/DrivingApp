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

func TestMigrationPlanEndsWithUserRoleMemberships(t *testing.T) {
	runner := NewRunner(nil, nil)
	last := runner.migrations[len(runner.migrations)-1]
	if last.version != 2026082306 || last.name != "add_user_role_memberships" {
		t.Fatalf("last migration = %d %q", last.version, last.name)
	}
}

func TestUserRoleMigrationBackfillsAndConstrainsMemberships(t *testing.T) {
	statements := strings.Join(userRoleMembershipStatements, "\n")
	for _, expected := range []string{
		"CREATE TABLE user_roles",
		"UNIQUE INDEX IF NOT EXISTS userrole_user_id_role",
		"INSERT INTO user_roles (user_id, role)",
		"user_roles_role_check",
		"user_roles_user_fk",
	} {
		if !strings.Contains(statements, expected) {
			t.Fatalf("user role migration is missing %q", expected)
		}
	}
}
