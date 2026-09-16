package postgres

import (
	"errors"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

func driverUnavailableError(operation string, err error) error {
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.ErrDriverUnavailable
	}
	return fmt.Errorf("%s: %w", operation, err)
}

func driverActiveRideConflictError(operation string, err error) error {
	var databaseError *pgconn.PgError
	if errors.As(err, &databaseError) &&
		databaseError.Code == "23505" &&
		databaseError.ConstraintName == "rides_one_active_ride_per_driver_idx" {
		return domain.ErrDriverHasActiveRide
	}
	return fmt.Errorf("%s: %w", operation, err)
}

func passengerActiveRideConflictError(operation string, err error) error {
	var databaseError *pgconn.PgError
	if errors.As(err, &databaseError) &&
		databaseError.Code == "23505" &&
		(databaseError.ConstraintName == "ride_passenger_id" ||
			databaseError.ConstraintName == "rides_one_active_ride_per_passenger_idx") {
		return domain.ErrActiveBooking
	}
	return fmt.Errorf("%s: %w", operation, err)
}
