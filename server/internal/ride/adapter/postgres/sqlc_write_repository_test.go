package postgres

import (
	"testing"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
)

func TestFromPostgresBidMapsGeneratedRow(t *testing.T) {
	item := databasepostgres.Bid{
		ID:                  13,
		RideID:              29,
		DriverID:            41,
		OfferedFareCentavos: 2750,
		Status:              "pending",
	}

	got := fromPostgresBid(item)
	if got.ID != 13 || got.RideID != 29 || got.DriverID != 41 || got.FareCentavos != 2750 || got.Status != "pending" {
		t.Fatalf("mapped bid = %+v", got)
	}
}

func TestPostgresRideValuesRemainPresentWhenZeroValued(t *testing.T) {
	if value := postgresRideFloat(0); !value.Valid || value.Float64 != 0 {
		t.Fatalf("postgresRideFloat(0) = %+v", value)
	}
	if value := postgresRideText(""); !value.Valid || value.String != "" {
		t.Fatalf("postgresRideText(\"\") = %+v", value)
	}
}
