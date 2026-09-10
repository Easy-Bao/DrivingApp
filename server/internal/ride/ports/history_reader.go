package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// RideHistoryReader supplies trip-history read models without exposing command
// persistence.
type RideHistoryReader interface {
	DriverTrips(ctx context.Context, driverID int, query domain.TripHistoryQuery) ([]domain.Ride, error)
	PassengerRides(ctx context.Context, passengerID int, query domain.TripHistoryQuery) ([]domain.Ride, error)
}

// RecentPassengerRidesReader keeps the passenger home query bounded to recent
// records.
type RecentPassengerRidesReader interface {
	PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]domain.Ride, error)
}
