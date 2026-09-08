package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5"
)

func (repository *PostgresRideRepository) Counterparty(ctx context.Context, rideID, actorID int) (domain.Counterparty, error) {
	ride, err := repository.Get(ctx, rideID)
	if err != nil {
		return domain.Counterparty{}, err
	}
	targetID, targetRole, err := counterpartyIdentityFromRide(ride, actorID)
	if err != nil {
		return domain.Counterparty{}, err
	}
	dbTargetID, err := toPostgresRideID(targetID, "counterparty id")
	if err != nil {
		return domain.Counterparty{}, err
	}
	account, err := repository.queries.GetUserByID(ctx, dbTargetID)
	if err != nil {
		return domain.Counterparty{}, fmt.Errorf("find counterparty account: %w", err)
	}
	result := domain.Counterparty{
		RideID:     ride.ID,
		UserID:     targetID,
		Role:       targetRole,
		Name:       rideTextValue(account.Name),
		RideStatus: ride.Status,
	}
	result.ContactAllowed, result.ContactAllowedUntil = rideContactAvailabilityFromRide(ride)
	if result.ContactAllowed {
		result.Phone = account.Phone
	}

	if targetRole == "driver" {
		profile, profileErr := repository.queries.GetDriverProfileByUserIDFull(ctx, dbTargetID)
		if profileErr != nil && !errors.Is(profileErr, pgx.ErrNoRows) {
			return domain.Counterparty{}, fmt.Errorf("find counterparty driver profile: %w", profileErr)
		}
		if profileErr == nil {
			result.Name = firstNonEmpty(profile.Name, result.Name)
			result.Rating = profile.Rating
			result.VehicleType = profile.VehicleType
			result.PlateNumber = profile.PlateNumber
		}
		return result, nil
	}

	profile, profileErr := repository.queries.GetPassengerProfileByUserIDFull(ctx, dbTargetID)
	if profileErr != nil && !errors.Is(profileErr, pgx.ErrNoRows) {
		return domain.Counterparty{}, fmt.Errorf("find counterparty passenger profile: %w", profileErr)
	}
	if profileErr == nil {
		result.Name = firstNonEmpty(profile.Name, result.Name)
	}
	return result, nil
}

func counterpartyIdentityFromRide(ride domain.Ride, actorID int) (int, string, error) {
	if ride.PassengerID == actorID {
		if ride.DriverID == nil || *ride.DriverID <= 0 {
			return 0, "", domain.ErrCounterpartyUnavailable
		}
		return *ride.DriverID, "driver", nil
	}
	if ride.DriverID != nil && *ride.DriverID == actorID {
		return ride.PassengerID, "passenger", nil
	}
	return 0, "", domain.ErrUnauthorizedRide
}

func rideContactAvailabilityFromRide(ride domain.Ride) (bool, *string) {
	switch ride.Status {
	case "assigned", "accepted", "arrived", "in_transit":
		return true, nil
	case "completed":
		if ride.CompletedAt == nil {
			return false, nil
		}
		completedAt, err := time.Parse(time.RFC3339, *ride.CompletedAt)
		if err != nil {
			return false, nil
		}
		until := completedAt.Add(rideContactWindow)
		formatted := until.UTC().Format(time.RFC3339)
		return time.Now().Before(until), &formatted
	default:
		return false, nil
	}
}
