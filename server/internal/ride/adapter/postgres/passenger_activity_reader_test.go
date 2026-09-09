package postgres

import (
	"testing"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
)

func TestFromPostgresPassengerActivitySummaryMapsTotals(t *testing.T) {
	summary, err := fromPostgresPassengerActivitySummary(databasepostgres.GetPassengerActivitySummaryRow{
		ThisWeekFareCentavos:   12_500,
		ThisWeekCompletedRides: 4,
	})
	if err != nil {
		t.Fatalf("fromPostgresPassengerActivitySummary() error = %v", err)
	}
	if summary.ThisWeekFareCentavos != 12_500 || summary.ThisWeekCompletedRides != 4 {
		t.Fatalf("mapped passenger activity summary = %+v", summary)
	}
}

func TestFromPostgresPassengerActivitySummaryRejectsNegativeRideCount(t *testing.T) {
	if _, err := fromPostgresPassengerActivitySummary(databasepostgres.GetPassengerActivitySummaryRow{
		ThisWeekCompletedRides: -1,
	}); err == nil {
		t.Fatal("expected negative completed ride count to be rejected")
	}
}
