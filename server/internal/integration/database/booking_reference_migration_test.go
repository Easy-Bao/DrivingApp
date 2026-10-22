//go:build integration

package database_test

import (
	"context"
	"fmt"
	"os"
	"regexp"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
)

func TestBookingReferenceMigrationBackfillsAndReservesReferences(t *testing.T) {
	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL is not set")
	}
	ctx, cancel := context.WithTimeout(t.Context(), 30*time.Second)
	defer cancel()
	connection, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatal("connect to test database")
	}
	schema := pgx.Identifier{fmt.Sprintf("booking_reference_it_%d", time.Now().UnixNano())}.Sanitize()
	if _, err := connection.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatalf("create test schema: %v", err)
	}
	t.Cleanup(func() {
		cleanup, done := context.WithTimeout(context.Background(), 5*time.Second)
		defer done()
		_, _ = connection.Exec(cleanup, "DROP SCHEMA "+schema+" CASCADE")
		_ = connection.Close(cleanup)
	})
	if _, err := connection.Exec(ctx, "SET search_path TO "+schema); err != nil {
		t.Fatal(err)
	}
	if _, err := connection.Exec(ctx, `
CREATE TABLE bid_sessions (id serial PRIMARY KEY);
CREATE TABLE rides (id serial PRIMARY KEY, bid_session_id integer REFERENCES bid_sessions(id));
INSERT INTO bid_sessions DEFAULT VALUES;
INSERT INTO bid_sessions DEFAULT VALUES;
INSERT INTO rides (bid_session_id) VALUES (1), (NULL);
`); err != nil {
		t.Fatal(err)
	}
	if err := executeEmbeddedMigration(ctx, connection, "2026102201_booking_references.up.sql"); err != nil {
		t.Fatalf("apply migration: %v", err)
	}
	var sessionReference, rideReference, directReference string
	if err := connection.QueryRow(ctx, `SELECT session.booking_reference, ride.booking_reference,
(SELECT booking_reference FROM rides WHERE id=2)
FROM bid_sessions AS session JOIN rides AS ride ON ride.bid_session_id=session.id WHERE session.id=1`).Scan(&sessionReference, &rideReference, &directReference); err != nil {
		t.Fatal(err)
	}
	format := regexp.MustCompile(`^7016[0-9]{11}$`)
	if sessionReference != rideReference || !format.MatchString(sessionReference) || !format.MatchString(directReference) || directReference == sessionReference {
		t.Fatalf("invalid backfill references: %q %q %q", sessionReference, rideReference, directReference)
	}
	var count, distinct int
	if err := connection.QueryRow(ctx, `SELECT count(*), count(DISTINCT reference) FROM (SELECT allocate_booking_reference() AS reference FROM generate_series(1,1000)) AS allocated`).Scan(&count, &distinct); err != nil {
		t.Fatal(err)
	}
	if count != 1000 || distinct != 1000 {
		t.Fatalf("allocations = %d distinct = %d", count, distinct)
	}
	// Repeat the PRNG sequence to force a real collision in the first candidate.
	if _, err := connection.Exec(ctx, `SELECT setseed(0.42)`); err != nil {
		t.Fatal(err)
	}
	var collision string
	if err := connection.QueryRow(ctx, `SELECT '7016' || lpad(floor(random()*100000000000)::bigint::text,11,'0')`).Scan(&collision); err != nil {
		t.Fatal(err)
	}
	if _, err := connection.Exec(ctx, `INSERT INTO booking_references(reference) VALUES($1) ON CONFLICT DO NOTHING`, collision); err != nil {
		t.Fatal(err)
	}
	if _, err := connection.Exec(ctx, `SELECT setseed(0.42)`); err != nil {
		t.Fatal(err)
	}
	var retried string
	if err := connection.QueryRow(ctx, `SELECT allocate_booking_reference()`).Scan(&retried); err != nil {
		t.Fatal(err)
	}
	if retried == collision || !format.MatchString(retried) {
		t.Fatalf("collision retry returned %q", retried)
	}
	if _, err := connection.Exec(ctx, `UPDATE rides SET booking_reference=(SELECT booking_reference FROM bid_sessions WHERE id=2) WHERE id=1`); err == nil {
		t.Fatal("accepted ride reference was allowed to differ from its booking")
	}
	if _, err := connection.Exec(ctx, `INSERT INTO booking_references(reference) VALUES('7016BAD')`); err == nil {
		t.Fatal("accepted malformed reference")
	}
	if err := executeEmbeddedMigration(ctx, connection, "2026102201_booking_references.down.sql"); err != nil {
		t.Fatalf("rollback migration: %v", err)
	}
	if _, err := connection.Exec(ctx, `INSERT INTO rides DEFAULT VALUES`); err != nil {
		t.Fatalf("legacy write after rollback: %v", err)
	}
}
