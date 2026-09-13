package postgres

import (
	"context"
	"fmt"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

func (repository *RideRepository) CreateRide(ctx context.Context, value domain.Ride) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	if value.PassengerID <= 0 || value.FareAmount <= 0 {
		return domain.Ride{}, domain.ErrInvalidTrip
	}
	status := value.Status
	if status == "" {
		status = string(domain.RideRequested)
	}
	normalizedStatus, ok := domain.NormalizeRideStatus(status)
	if !ok || normalizedStatus != domain.RideRequested {
		return domain.Ride{}, domain.ErrInvalidTrip
	}
	passengerID, err := toPostgresRideID(value.PassengerID, "passenger id")
	if err != nil {
		return domain.Ride{}, err
	}
	item, err := repository.queries.CreateRide(ctx, databasepostgres.CreateRideParams{
		PassengerID:      passengerID,
		Status:           string(normalizedStatus),
		FareAmount:       value.FareAmount,
		RideType:         value.RideType,
		PickupLatitude:   rideFloat(value.PickupLatitude),
		PickupLongitude:  rideFloat(value.PickupLongitude),
		PickupName:       rideText(value.PickupName),
		DropoffLatitude:  rideFloat(value.DropoffLatitude),
		DropoffLongitude: rideFloat(value.DropoffLongitude),
		DropoffName:      rideText(value.DropoffName),
		DistanceKm:       rideFloat(value.DistanceKm),
		DurationMinutes:  rideFloat(value.DurationMinutes),
	})
	if err != nil {
		return domain.Ride{}, fmt.Errorf("create ride: %w", err)
	}
	ride, err := fromPostgresRide(item)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("map created ride: %w", err)
	}
	return ride, nil
}

func rideFloat(value float64) pgtype.Float8 {
	return pgtype.Float8{Float64: value, Valid: true}
}

func rideText(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}
