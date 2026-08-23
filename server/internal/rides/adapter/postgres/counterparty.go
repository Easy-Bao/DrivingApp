package postgres

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/passengerprofile"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

const rideContactWindow = 48 * time.Hour

func (repository *Repository) Counterparty(ctx context.Context, rideID, actorID int) (domain.Counterparty, error) {
	ride, err := repository.client.Ride.Get(ctx, rideID)
	if err != nil {
		return domain.Counterparty{}, err
	}

	targetID, targetRole, err := counterpartyIdentity(ride, actorID)
	if err != nil {
		return domain.Counterparty{}, err
	}
	account, err := repository.client.User.Get(ctx, targetID)
	if err != nil {
		return domain.Counterparty{}, err
	}

	result := domain.Counterparty{
		RideID: ride.ID, UserID: targetID, Role: targetRole, Name: account.Name,
		RideStatus: ride.Status,
	}
	result.ContactAllowed, result.ContactAllowedUntil = rideContactAvailability(ride)
	if result.ContactAllowed {
		result.Phone = account.Phone
	}

	if targetRole == "driver" {
		profile, profileErr := repository.client.DriverProfile.Query().Where(
			driverprofile.UserIDEQ(targetID),
		).Only(ctx)
		if profileErr != nil && !ent.IsNotFound(profileErr) {
			return domain.Counterparty{}, profileErr
		}
		if profile != nil {
			result.Name = firstNonEmpty(profile.Name, result.Name)
			result.Rating = profile.Rating
			result.VehicleType = profile.VehicleType
			result.PlateNumber = profile.PlateNumber
		}
		return result, nil
	}

	profile, profileErr := repository.client.PassengerProfile.Query().Where(
		passengerprofile.UserIDEQ(targetID),
	).Only(ctx)
	if profileErr != nil && !ent.IsNotFound(profileErr) {
		return domain.Counterparty{}, profileErr
	}
	if profile != nil {
		result.Name = firstNonEmpty(profile.Name, result.Name)
	}
	return result, nil
}

func counterpartyIdentity(ride *ent.Ride, actorID int) (int, string, error) {
	if ride.PassengerID == actorID {
		if ride.DriverID <= 0 {
			return 0, "", domain.ErrCounterpartyUnavailable
		}
		return ride.DriverID, "driver", nil
	}
	if ride.DriverID == actorID {
		return ride.PassengerID, "passenger", nil
	}
	return 0, "", domain.ErrUnauthorizedRide
}

func rideContactAvailability(ride *ent.Ride) (bool, *string) {
	switch ride.Status {
	case "assigned", "accepted", "arrived", "in_transit":
		return true, nil
	case "completed":
		if ride.CompletedAt.IsZero() {
			return false, nil
		}
		until := ride.CompletedAt.Add(rideContactWindow)
		formatted := until.UTC().Format(time.RFC3339)
		return time.Now().Before(until), &formatted
	default:
		return false, nil
	}
}

func firstNonEmpty(preferred, fallback string) string {
	if preferred != "" {
		return preferred
	}
	return fallback
}
