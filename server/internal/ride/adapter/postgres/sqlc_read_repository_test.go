package postgres

import (
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestNewPostgresRideRepositoryRejectsMissingDependencies(t *testing.T) {
	if _, err := NewPostgresRideRepository(nil, nil, 1500); err == nil {
		t.Fatal("expected missing compatibility client to be rejected")
	}
}

func TestFromPostgresRideMapsOptionalFieldsAndTimestamps(t *testing.T) {
	item := databasepostgres.Ride{
		ID:             19,
		PassengerID:    7,
		DriverID:       pgtype.Int4{Int32: 11, Valid: true},
		Status:         "assigned",
		FareCentavos:   3200,
		RideType:       "solo",
		PickupLatitude: pgtype.Float8{Float64: 14.6, Valid: true},
		PickupName:     pgtype.Text{String: "Makati", Valid: true},
		DriverName:     pgtype.Text{String: "Ada", Valid: true},
		CreatedAt: pgtype.Timestamptz{
			Time:  time.Date(2026, time.January, 2, 3, 4, 5, 0, time.FixedZone("PHT", 8*60*60)),
			Valid: true,
		},
		PaymentStatus: "unpaid",
		CommissionBps: pgtype.Int8{Int64: 1500, Valid: true},
	}

	ride, err := fromPostgresRide(item)
	if err != nil {
		t.Fatalf("fromPostgresRide() error = %v", err)
	}
	if ride.ID != 19 || ride.DriverID == nil || *ride.DriverID != 11 || ride.PickupName != "Makati" || ride.DriverName != "Ada" {
		t.Fatalf("mapped ride = %+v", ride)
	}
	if ride.CreatedAt == nil || *ride.CreatedAt != "2026-01-01T19:04:05Z" {
		t.Fatalf("mapped creation time = %v", ride.CreatedAt)
	}
	if ride.CommissionBPS == nil || *ride.CommissionBPS != 1500 {
		t.Fatalf("mapped commission = %v", ride.CommissionBPS)
	}
}

func TestFromPostgresRideRejectsMissingCreationTime(t *testing.T) {
	if _, err := fromPostgresRide(databasepostgres.Ride{}); err == nil {
		t.Fatal("expected missing ride creation time to be rejected")
	}
}

func TestFromPostgresDriverStatsMapsMetrics(t *testing.T) {
	stats, err := fromPostgresDriverStats(7, databasepostgres.GetDriverStatsRow{
		TotalTrips:            12,
		CompletedTrips:        8,
		ActiveTrips:           2,
		TotalEarningsCentavos: 48_000,
		TodayCompletedTrips:   3,
		TodayEarningsCentavos: 15_000,
		AverageRating:         4.75,
	})
	if err != nil {
		t.Fatalf("fromPostgresDriverStats() error = %v", err)
	}
	if stats.DriverID != 7 || stats.TotalTrips != 12 || stats.CompletedTrips != 8 || stats.ActiveTrips != 2 ||
		stats.TotalEarnings != 48_000 || stats.TodayCompletedTrips != 3 || stats.TodayEarnings != 15_000 ||
		stats.AverageRating != 4.75 {
		t.Fatalf("mapped driver stats = %+v", stats)
	}
}

func TestFromPostgresDriverEarningFallsBackToCreationTime(t *testing.T) {
	createdAt := time.Date(2026, time.January, 2, 3, 4, 5, 0, time.FixedZone("PHT", 8*60*60))
	entry, err := fromPostgresDriverEarning(databasepostgres.ListDriverEarningsRow{
		CreatedAt:            pgtype.Timestamptz{Time: createdAt, Valid: true},
		DriverPayoutCentavos: 1_250,
	})
	if err != nil {
		t.Fatalf("fromPostgresDriverEarning() error = %v", err)
	}
	if !entry.CompletedAt.Equal(createdAt) || entry.PayoutCentavos != 1_250 {
		t.Fatalf("mapped driver earning = %+v", entry)
	}
}

func TestFromPostgresDriverEarningUsesCompletedTime(t *testing.T) {
	createdAt := time.Date(2026, time.January, 2, 3, 4, 5, 0, time.UTC)
	completedAt := createdAt.Add(45 * time.Minute)
	entry, err := fromPostgresDriverEarning(databasepostgres.ListDriverEarningsRow{
		CreatedAt:   pgtype.Timestamptz{Time: createdAt, Valid: true},
		CompletedAt: pgtype.Timestamptz{Time: completedAt, Valid: true},
	})
	if err != nil {
		t.Fatalf("fromPostgresDriverEarning() error = %v", err)
	}
	if !entry.CompletedAt.Equal(completedAt) {
		t.Fatalf("mapped completion time = %v", entry.CompletedAt)
	}
}

func TestToNativeRideCountRejectsNegativeValues(t *testing.T) {
	if _, err := toNativeRideCount(-1, "trip count"); err == nil {
		t.Fatal("expected negative trip count to be rejected")
	}
}

func TestToPostgresRideIDRequiresPositiveInt32(t *testing.T) {
	if got, err := toPostgresRideID(7, "ride id"); err != nil || got != 7 {
		t.Fatalf("toPostgresRideID(7) = %d, %v", got, err)
	}
	for _, value := range []int{0, -1, maxPostgresRideID + 1} {
		if _, err := toPostgresRideID(value, "ride id"); err == nil {
			t.Errorf("toPostgresRideID(%d) succeeded", value)
		}
	}
}
