//go:build integration

package database_test

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestAnalyticsQueriesPreserveRatingsAndRideCounts(t *testing.T) {
	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	admin, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatalf("connect to test PostgreSQL database: %v", err)
	}

	schemaName := fmt.Sprintf("analytics_it_%d", time.Now().UnixNano())
	quotedSchema := pgx.Identifier{schemaName}.Sanitize()
	if _, err := admin.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		_ = admin.Close(context.Background())
		t.Fatalf("create isolated test schema: %v", err)
	}

	var connection *pgx.Conn
	t.Cleanup(func() {
		cleanupContext, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		if connection != nil {
			_ = connection.Close(cleanupContext)
		}
		_, _ = admin.Exec(cleanupContext, "DROP SCHEMA "+quotedSchema+" CASCADE")
		_ = admin.Close(cleanupContext)
	})

	config, err := pgx.ParseConfig(databaseURL)
	if err != nil {
		t.Fatalf("parse test PostgreSQL connection: %v", err)
	}
	config.RuntimeParams["search_path"] = schemaName
	connection, err = pgx.ConnectConfig(ctx, config)
	if err != nil {
		t.Fatalf("connect to isolated test schema: %v", err)
	}

	_, err = connection.Exec(ctx, `
CREATE TABLE users (
    id integer PRIMARY KEY,
    account_status text NOT NULL,
    is_verified boolean NOT NULL
);
CREATE TABLE driver_profiles (
    id integer PRIMARY KEY,
    user_id integer NOT NULL UNIQUE,
    name text NOT NULL,
    vehicle_type text NOT NULL,
    plate_number text NOT NULL,
    rating double precision NOT NULL,
    is_online boolean NOT NULL,
    online_last_seen_at timestamptz
);
CREATE TABLE rides (
    id integer PRIMARY KEY,
    driver_id integer NOT NULL,
    status text NOT NULL,
    completed_at timestamptz,
    created_at timestamptz NOT NULL,
    cancellation_responsibility text NOT NULL DEFAULT ''
);
CREATE TABLE ride_settlements (
    ride_id integer PRIMARY KEY,
    driver_payout_amount bigint NOT NULL
);
CREATE TABLE reviews (
    id integer PRIMARY KEY,
    driver_id integer NOT NULL,
    rating double precision NOT NULL
);`)
	if err != nil {
		t.Fatalf("create analytics query schema: %v", err)
	}

	now := time.Now().UTC()
	dayStart := now.Truncate(24 * time.Hour)
	dayEnd := dayStart.Add(24 * time.Hour)
	onlineCutoff := now.Add(-time.Hour)
	lastSeen := now.Add(-time.Minute)
	if _, err := connection.Exec(ctx, `
INSERT INTO users (id, account_status, is_verified) VALUES
    (11, 'active', true),
    (12, 'active', true),
    (13, 'active', true),
    (14, 'suspended', true);`); err != nil {
		t.Fatalf("seed analytics users: %v", err)
	}
	if _, err := connection.Exec(ctx, `
INSERT INTO driver_profiles (
    id, user_id, name, vehicle_type, plate_number, rating, is_online, online_last_seen_at
) VALUES
    (1, 11, 'Reviewed driver', 'sedan', 'ABC-111', 0, true, $1),
    (2, 12, 'Unreviewed driver', 'suv', 'ABC-222', 3.25, true, $1),
    (3, 13, 'Limited driver', 'sedan', 'ABC-333', 0, true, $1),
    (4, 14, 'Suspended driver', 'suv', 'ABC-444', 5, true, $1);`, lastSeen); err != nil {
		t.Fatalf("seed analytics driver profiles: %v", err)
	}
	if _, err := connection.Exec(ctx, `
INSERT INTO rides (id, driver_id, status, completed_at, created_at, cancellation_responsibility) VALUES
    (1, 11, 'completed', $1, $1, ''),
    (2, 11, 'cancelled', NULL, $2, 'driver_fault'),
    (3, 11, 'accepted', NULL, $2, ''),
    (4, 12, 'in_transit', NULL, $2, ''),
    (5, 12, 'requested', NULL, $2, ''),
    (6, 13, 'arrived', NULL, $2, '');`, dayStart.Add(time.Hour), dayStart); err != nil {
		t.Fatalf("seed analytics rides: %v", err)
	}
	if _, err := connection.Exec(ctx, "INSERT INTO ride_settlements (ride_id, driver_payout_amount) VALUES (1, 700)"); err != nil {
		t.Fatalf("seed analytics settlement: %v", err)
	}
	if _, err := connection.Exec(ctx, `
INSERT INTO reviews (id, driver_id, rating) VALUES
    (1, 11, 4),
    (2, 11, 5),
    (3, 13, 5);`); err != nil {
		t.Fatalf("seed analytics reviews: %v", err)
	}

	queries := databasepostgres.New(connection)
	onlineDrivers, err := queries.ListOnlineDrivers(ctx, databasepostgres.ListOnlineDriversParams{
		OnlineCutoff: pgtype.Timestamptz{Time: onlineCutoff, Valid: true},
		DriverIds:    []int32{11, 12, 13},
		Limit:        2,
	})
	if err != nil {
		t.Fatalf("list online drivers: %v", err)
	}
	if len(onlineDrivers) != 2 {
		t.Fatalf("online driver count = %d, want 2", len(onlineDrivers))
	}
	if onlineDrivers[0].ID != 1 || onlineDrivers[0].UserID != 11 || onlineDrivers[0].Rating != 4.5 || onlineDrivers[0].OnboardPassengerCount != 2 {
		t.Fatalf("first online driver = %+v, want profile 1 with review average 4.5 and 2 onboard rides", onlineDrivers[0])
	}
	if onlineDrivers[1].ID != 2 || onlineDrivers[1].UserID != 12 || onlineDrivers[1].Rating != 3.25 || onlineDrivers[1].OnboardPassengerCount != 1 {
		t.Fatalf("second online driver = %+v, want profile 2 with fallback rating 3.25 and 1 onboard ride", onlineDrivers[1])
	}

	publicSummaries, err := queries.ListPublicDriverSummaries(ctx, databasepostgres.ListPublicDriverSummariesParams{
		OnlineCutoff: pgtype.Timestamptz{Time: onlineCutoff, Valid: true},
		Limit:        2,
	})
	if err != nil {
		t.Fatalf("list public driver summaries: %v", err)
	}
	if len(publicSummaries) != 2 {
		t.Fatalf("public driver summary count = %d, want 2", len(publicSummaries))
	}
	if publicSummaries[0].ID != 11 || publicSummaries[0].Rating != 4.5 || publicSummaries[1].ID != 12 || publicSummaries[1].Rating != 3.25 {
		t.Fatalf("public driver summaries = %+v, want review average and stored-rating fallback in profile order", publicSummaries)
	}

	stats, err := queries.GetDriverStats(ctx, databasepostgres.GetDriverStatsParams{
		DayStart: pgtype.Timestamptz{Time: dayStart, Valid: true},
		DayEnd:   pgtype.Timestamptz{Time: dayEnd, Valid: true},
		DriverID: 11,
	})
	if err != nil {
		t.Fatalf("get driver statistics: %v", err)
	}
	if stats.TotalTrips != 3 || stats.CompletedTrips != 1 || stats.ActiveTrips != 1 {
		t.Fatalf("trip totals = total %d, completed %d, active %d; want 3, 1, 1", stats.TotalTrips, stats.CompletedTrips, stats.ActiveTrips)
	}
	if stats.TotalEarningsAmount != 700 || stats.TodayCompletedTrips != 1 || stats.TodayEarningsAmount != 700 {
		t.Fatalf("earnings = total %d, today trips %d, today amount %d; want 700, 1, 700", stats.TotalEarningsAmount, stats.TodayCompletedTrips, stats.TodayEarningsAmount)
	}
	if stats.AverageRating != 4.5 || stats.FourStarCount != 1 || stats.FiveStarCount != 1 {
		t.Fatalf("rating statistics = average %.2f, four-star %d, five-star %d; want 4.50, 1, 1", stats.AverageRating, stats.FourStarCount, stats.FiveStarCount)
	}
	if stats.StandingSettledTrips != 2 || stats.DriverFaultCancellationCount != 1 {
		t.Fatalf("standing statistics = settled %d, driver-fault cancellations %d; want 2, 1", stats.StandingSettledTrips, stats.DriverFaultCancellationCount)
	}
}
