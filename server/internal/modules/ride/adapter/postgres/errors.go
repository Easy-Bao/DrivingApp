package postgres

import (
	"errors"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

func driverUnavailableError(operation string, err error, unavailable error) error {
	if errors.Is(err, pgx.ErrNoRows) {
		return unavailable
	}
	return fmt.Errorf("%s: %w", operation, err)
}

func driverActiveRideConflictError(operation string, err error) error {
	if constraint, ok := postgresUniqueConstraint(err); ok && constraint == "rides_one_active_ride_per_driver_idx" {
		return domain.ErrDriverCapacityReached
	}
	return fmt.Errorf("%s: %w", operation, err)
}

func passengerActiveRideConflictError(operation string, err error) error {
	if constraint, ok := postgresUniqueConstraint(err); ok &&
		(constraint == "ride_passenger_id" || constraint == "rides_one_active_ride_per_passenger_idx") {
		return domain.ErrActiveBooking
	}
	return fmt.Errorf("%s: %w", operation, err)
}

func acceptedRideConflictError(operation string, err error) error {
	if constraint, ok := postgresUniqueConstraint(err); ok {
		switch constraint {
		case "ride_passenger_id", "rides_one_active_ride_per_passenger_idx":
			return domain.ErrActiveBooking
		case "rides_one_active_ride_per_driver_idx":
			return domain.ErrDriverCapacityReached
		}
	}
	return fmt.Errorf("%s: %w", operation, err)
}

func isPostgresUniqueViolation(err error) bool {
	_, ok := postgresUniqueConstraint(err)
	return ok
}

func postgresUniqueConstraint(err error) (string, bool) {
	databaseError, ok := errors.AsType[*pgconn.PgError](err)
	if !ok || databaseError.Code != "23505" {
		return "", false
	}
	return databaseError.ConstraintName, true
}
