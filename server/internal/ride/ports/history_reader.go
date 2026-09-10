package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// RideHistoryReader exposes read-only trip history projections.
type RideHistoryReader interface {
	DriverTrips(ctx context.Context, driverID int, query domain.TripHistoryQuery) ([]domain.Ride, error)
	PassengerRides(ctx context.Context, passengerID int, query domain.TripHistoryQuery) ([]domain.Ride, error)
}

// RecentPassengerRidesReader exposes the bounded recent-rides projection.
type RecentPassengerRidesReader interface {
	PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]domain.Ride, error)
}
