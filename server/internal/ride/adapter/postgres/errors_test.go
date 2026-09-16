package postgres

import (
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgconn"
)

func TestDriverActiveRideConflictError(t *testing.T) {
	err := &pgconn.PgError{
		Code:           "23505",
		ConstraintName: "rides_one_active_ride_per_driver_idx",
	}
	if !errors.Is(driverActiveRideConflictError("assign ride", err), domain.ErrDriverHasActiveRide) {
		t.Fatal("expected active ride conflict to map to the domain error")
	}

	other := &pgconn.PgError{Code: "23505", ConstraintName: "another_unique_index"}
	if errors.Is(driverActiveRideConflictError("assign ride", other), domain.ErrDriverHasActiveRide) {
		t.Fatal("unexpectedly mapped another unique violation to the active ride error")
	}
}

func TestPassengerActiveRideConflictError(t *testing.T) {
	err := &pgconn.PgError{
		Code:           "23505",
		ConstraintName: "ride_passenger_id",
	}
	if !errors.Is(passengerActiveRideConflictError("create ride", err), domain.ErrActiveBooking) {
		t.Fatal("expected passenger active ride conflict to map to domain.ErrActiveBooking")
	}

	other := &pgconn.PgError{Code: "23505", ConstraintName: "another_unique_index"}
	if errors.Is(passengerActiveRideConflictError("create ride", other), domain.ErrActiveBooking) {
		t.Fatal("unexpectedly mapped another unique violation to the active ride error")
	}
}
