package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// RideLifecycleStore is the atomic boundary for participant-authorized state
// changes.
type RideLifecycleStore interface {
	RideReader
	AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error)
	MarkArrived(ctx context.Context, rideID, driverID int, currentStatus string) (domain.Ride, error)
	StartTrip(ctx context.Context, rideID, driverID int) (domain.Ride, error)
	CompleteTrip(ctx context.Context, rideID, driverID int) (domain.Ride, error)
	MarkPassengerNoShow(ctx context.Context, rideID, driverID int) (domain.Ride, error)
	UpdateStatus(
		ctx context.Context,
		rideID, actorID int,
		currentStatus, nextStatus string,
		transition domain.RideTransition,
	) (domain.Ride, error)
}
