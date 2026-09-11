package postgres

import (
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestFromPostgresDriverRideMapsPassengerDetails(t *testing.T) {
	ride, err := fromPostgresDriverRide(databasepostgres.ListDriverRidesRow{
		Ride: databasepostgres.Ride{
			ID:        19,
			CreatedAt: pgtype.Timestamptz{Time: time.Now(), Valid: true},
		},
		PassengerName:     "Passenger",
		PassengerPhone:    "+639171234567",
		PassengerRating:   pgtype.Float8{Float64: 4.5, Valid: true},
		PassengerFeedback: pgtype.Text{String: "  Great passenger  ", Valid: true},
	})
	if err != nil {
		t.Fatalf("fromPostgresDriverRide() error = %v", err)
	}
	invalidPassengerName := ride.PassengerName != "Passenger"
	invalidPassengerPhone := ride.PassengerPhone != "+639171234567"
	invalidPassengerRating := ride.PassengerRating != 4.5
	invalidPassengerFeedback := ride.PassengerFeedback != "Great passenger"
	if invalidPassengerName || invalidPassengerPhone || invalidPassengerRating || invalidPassengerFeedback {
		t.Fatalf("mapped passenger details = %+v", ride)
	}
}

func TestFromPostgresPassengerRideUsesDriverProfileFallback(t *testing.T) {
	ride, err := fromPostgresPassengerRide(databasepostgres.ListPassengerRidesRow{
		Ride: databasepostgres.Ride{
			ID:        23,
			CreatedAt: pgtype.Timestamptz{Time: time.Now(), Valid: true},
		},
		DriverProfileName:        "Driver",
		DriverProfileVehicleType: "Sedan",
		DriverProfilePlateNumber: "ABC 123",
	})
	if err != nil {
		t.Fatalf("fromPostgresPassengerRide() error = %v", err)
	}
	if ride.DriverName != "Driver" || ride.VehicleType != "Sedan" || ride.PlateNumber != "ABC 123" {
		t.Fatalf("mapped driver details = %+v", ride)
	}
}

func TestFromPostgresPassengerRidePreservesRideSnapshot(t *testing.T) {
	ride, err := fromPostgresPassengerRide(databasepostgres.ListPassengerRidesRow{
		Ride: databasepostgres.Ride{
			ID:          29,
			DriverName:  pgtype.Text{String: "Snapshot Driver", Valid: true},
			VehicleType: pgtype.Text{String: "Van", Valid: true},
			PlateNumber: pgtype.Text{String: "XYZ 789", Valid: true},
			CreatedAt:   pgtype.Timestamptz{Time: time.Now(), Valid: true},
		},
		DriverProfileName:        "Profile Driver",
		DriverProfileVehicleType: "Sedan",
		DriverProfilePlateNumber: "PROFILE 1",
	})
	if err != nil {
		t.Fatalf("fromPostgresPassengerRide() error = %v", err)
	}
	if ride.DriverName != "Snapshot Driver" || ride.VehicleType != "Van" || ride.PlateNumber != "XYZ 789" {
		t.Fatalf("ride snapshot was overwritten = %+v", ride)
	}
}

func TestToPostgresPaginationValueRejectsNegativeValues(t *testing.T) {
	if _, err := toPostgresPaginationValue(-1, "offset"); err == nil {
		t.Fatal("expected negative pagination value to be rejected")
	}
	if value, err := toPostgresPaginationValue(25, "limit"); err != nil || value != 25 {
		t.Fatalf("toPostgresPaginationValue(25) = %d, %v", value, err)
	}
}
