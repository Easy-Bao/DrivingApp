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
	tests := []struct {
		name           string
		constraintName string
		wantConflict   bool
	}{
		{
			name:           "legacy passenger uniqueness constraint",
			constraintName: "ride_passenger_id",
			wantConflict:   true,
		},
		{
			name:           "active passenger uniqueness constraint",
			constraintName: "rides_one_active_ride_per_passenger_idx",
			wantConflict:   true,
		},
		{
			name:           "unrelated uniqueness constraint",
			constraintName: "another_unique_index",
			wantConflict:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := &pgconn.PgError{
				Code:           "23505",
				ConstraintName: tt.constraintName,
			}
			gotConflict := errors.Is(
				passengerActiveRideConflictError("create ride", err),
				domain.ErrActiveBooking,
			)
			if gotConflict != tt.wantConflict {
				t.Fatalf("active booking conflict = %t, want %t", gotConflict, tt.wantConflict)
			}
		})
	}
}

func TestAcceptedRideConflictError(t *testing.T) {
	tests := []struct {
		name           string
		constraintName string
		wantErr        error
	}{
		{
			name:           "legacy passenger uniqueness constraint maps to active booking",
			constraintName: "ride_passenger_id",
			wantErr:        domain.ErrActiveBooking,
		},
		{
			name:           "active passenger uniqueness constraint maps to active booking",
			constraintName: "rides_one_active_ride_per_passenger_idx",
			wantErr:        domain.ErrActiveBooking,
		},
		{
			name:           "active driver uniqueness constraint maps to driver active ride",
			constraintName: "rides_one_active_ride_per_driver_idx",
			wantErr:        domain.ErrDriverHasActiveRide,
		},
		{
			name:           "unrelated uniqueness constraint",
			constraintName: "another_unique_index",
			wantErr:        nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := &pgconn.PgError{
				Code:           "23505",
				ConstraintName: tt.constraintName,
			}
			mappedErr := acceptedRideConflictError("create accepted ride", err)
			if tt.wantErr != nil {
				if !errors.Is(mappedErr, tt.wantErr) {
					t.Fatalf("acceptedRideConflictError() = %v, want %v", mappedErr, tt.wantErr)
				}
			} else {
				if errors.Is(mappedErr, domain.ErrActiveBooking) || errors.Is(mappedErr, domain.ErrDriverHasActiveRide) {
					t.Fatalf("unexpectedly mapped unrelated error to domain conflict: %v", mappedErr)
				}
			}
		})
	}
}
