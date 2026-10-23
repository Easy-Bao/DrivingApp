//go:build integration

package database_test

import (
	"context"
	"fmt"
	"os"
	"reflect"
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestHistoryAndReviewCursorPagination(t *testing.T) {
	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL is not set")
	}
	ctx, cancel := context.WithTimeout(t.Context(), 30*time.Second)
	defer cancel()
	conn, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatal(err)
	}
	schema := pgx.Identifier{fmt.Sprintf("cursor_pagination_%d", time.Now().UnixNano())}.Sanitize()
	if _, err := conn.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cleanup, done := context.WithTimeout(context.Background(), 5*time.Second)
		defer done()
		_, _ = conn.Exec(cleanup, "DROP SCHEMA "+schema+" CASCADE")
		_ = conn.Close(cleanup)
	})
	if _, err := conn.Exec(ctx, "SET search_path TO "+schema); err != nil {
		t.Fatal(err)
	}
	if _, err := conn.Exec(ctx, `
CREATE TABLE users (id integer PRIMARY KEY, name text, phone text);
CREATE TABLE bid_sessions (id integer PRIMARY KEY, booking_reference text, UNIQUE(id,booking_reference));
CREATE TABLE passenger_profiles (user_id integer PRIMARY KEY, name text);
CREATE TABLE driver_profiles (user_id integer PRIMARY KEY, name text, vehicle_type text, plate_number text);
INSERT INTO users VALUES (1,'Passenger',''),(2,'Driver',''),(3,'Other','');`); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"booking_references", "rides", "ride_settlements", "reviews"} {
		ddl, err := os.ReadFile("../../../db/schema/" + name + ".sql")
		if err != nil {
			t.Fatal(err)
		}
		if _, err := conn.Exec(ctx, string(ddl)); err != nil {
			t.Fatalf("create %s: %v", name, err)
		}
	}
	if _, err := conn.Exec(ctx, `
INSERT INTO rides(id,passenger_id,driver_id,status,fare_amount,created_at)
SELECT id,1,2,'completed',1000,'2026-10-23 10:00:00.123456+00' FROM generate_series(1,6) id;
INSERT INTO reviews(id,ride_id,driver_id,passenger_id,rating,created_at)
SELECT id,id,2,1,5,created_at FROM rides;`); err != nil {
		t.Fatal(err)
	}

	if err := executeEmbeddedMigration(ctx, conn, "2026102302_review_index_cleanup.down.sql"); err != nil {
		t.Fatal(err)
	}
	if err := executeEmbeddedMigration(ctx, conn, "2026102302_review_index_cleanup.up.sql"); err != nil {
		t.Fatal(err)
	}
	var retained, removed bool
	if err := conn.QueryRow(ctx, "SELECT to_regclass('reviews_driver_created_id_idx') IS NOT NULL, to_regclass('review_driver_id_created_at') IS NULL").Scan(&retained, &removed); err != nil || !retained || !removed {
		t.Fatalf("retained=%v removed=%v err=%v", retained, removed, err)
	}
	queries := databasepostgres.New(conn)
	type boundary struct {
		at pgtype.Timestamptz
		id int32
	}
	driver := func(b boundary, offset int32) ([]int32, error) {
		rows, err := queries.ListDriverRides(ctx, databasepostgres.ListDriverRidesParams{DriverID: pgtype.Int4{Int32: 2, Valid: true}, Limit: 2, Offset: offset, BeforeCreatedAt: b.at, BeforeID: b.id})
		ids := []int32{}
		for _, row := range rows {
			ids = append(ids, row.Ride.ID)
		}
		return ids, err
	}
	passenger := func(b boundary, offset int32) ([]int32, error) {
		rows, err := queries.ListPassengerRides(ctx, databasepostgres.ListPassengerRidesParams{PassengerID: 1, Limit: 2, Offset: offset, BeforeCreatedAt: b.at, BeforeID: b.id})
		ids := []int32{}
		for _, row := range rows {
			ids = append(ids, row.Ride.ID)
		}
		return ids, err
	}
	review := func(b boundary, offset int32) ([]int32, error) {
		rows, err := queries.ListDriverReviews(ctx, databasepostgres.ListDriverReviewsParams{DriverID: 2, Limit: 2, Offset: offset, BeforeCreatedAt: b.at, BeforeID: b.id})
		ids := []int32{}
		for _, row := range rows {
			ids = append(ids, row.ID)
		}
		return ids, err
	}
	assertPage := func(fetch func(boundary, int32) ([]int32, error), b boundary, offset int32, want []int32) {
		t.Helper()
		got, err := fetch(b, offset)
		if err != nil || !reflect.DeepEqual(got, want) {
			t.Fatalf("page=%v want=%v err=%v", got, want, err)
		}
	}
	for _, fetch := range []func(boundary, int32) ([]int32, error){driver, passenger, review} {
		assertPage(fetch, boundary{}, 0, []int32{6, 5})
	}
	if _, err := conn.Exec(ctx, `
INSERT INTO rides(id,passenger_id,driver_id,status,fare_amount,created_at) VALUES
 (7,1,2,'completed',1000,'2026-10-23 11:00:00+00'),
 (8,3,3,'completed',1000,'2026-10-23 10:00:00.123456+00');
INSERT INTO reviews(id,ride_id,driver_id,passenger_id,rating,created_at) SELECT id,id,driver_id,passenger_id,5,created_at FROM rides WHERE id>=7;
DELETE FROM rides WHERE id=5;`); err != nil {
		t.Fatal(err)
	}
	at, _ := time.Parse(time.RFC3339Nano, "2026-10-23T10:00:00.123456Z")
	for _, fetch := range []func(boundary, int32) ([]int32, error){driver, passenger, review} {
		assertPage(fetch, boundary{pgtype.Timestamptz{Time: at, Valid: true}, 5}, 0, []int32{4, 3})
		assertPage(fetch, boundary{pgtype.Timestamptz{Time: at, Valid: true}, 3}, 0, []int32{2, 1})
		assertPage(fetch, boundary{pgtype.Timestamptz{Time: at, Valid: true}, 1}, 0, []int32{})
		assertPage(fetch, boundary{}, 2, []int32{4, 3})
	}
	// Changing membership does not recreate a frozen snapshot; active scope still
	// excludes completed rows, and actor predicates remain authoritative.
	active, err := queries.ListDriverRides(ctx, databasepostgres.ListDriverRidesParams{DriverID: pgtype.Int4{Int32: 2, Valid: true}, ActiveOnly: true, Limit: 2, BeforeCreatedAt: pgtype.Timestamptz{Time: at, Valid: true}, BeforeID: 5})
	if err != nil || len(active) != 0 {
		t.Fatalf("active=%v err=%v", active, err)
	}
	if err := executeEmbeddedMigration(ctx, conn, "2026102302_review_index_cleanup.down.sql"); err != nil {
		t.Fatal(err)
	}
	var restored bool
	if err := conn.QueryRow(ctx, "SELECT to_regclass('review_driver_id_created_at') IS NOT NULL").Scan(&restored); err != nil || !restored {
		t.Fatalf("restored=%v err=%v", restored, err)
	}
}
