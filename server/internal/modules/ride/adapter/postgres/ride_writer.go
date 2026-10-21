package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
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

	// Share the passenger lock used by bid-session creation so the
	// one-active-booking policy holds across both tables.
	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin create ride transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()
	transactionQueries := repository.queries.WithTx(transaction)
	if _, err := transactionQueries.LockUserForBidSession(ctx, passengerID); err != nil {
		return domain.Ride{}, fmt.Errorf("lock passenger for ride creation: %w", err)
	}
	now := pgtype.Timestamptz{Time: time.Now().UTC(), Valid: true}
	if err := transactionQueries.ExpireBidSessions(ctx, databasepostgres.ExpireBidSessionsParams{
		PassengerID: passengerID,
		ExpiresAt:   now,
	}); err != nil {
		return domain.Ride{}, fmt.Errorf("expire previous bid sessions: %w", err)
	}
	activeSession, err := transactionQueries.HasActiveBidSession(ctx, databasepostgres.HasActiveBidSessionParams{
		PassengerID: passengerID,
		ExpiresAt:   now,
	})
	if err != nil {
		return domain.Ride{}, fmt.Errorf("check active bid session: %w", err)
	}
	if activeSession {
		return domain.Ride{}, domain.ErrActiveBooking
	}
	activeRide, err := transactionQueries.HasActivePassengerRide(ctx, passengerID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("check active passenger ride: %w", err)
	}
	if activeRide {
		return domain.Ride{}, domain.ErrActiveBooking
	}

	item, err := transactionQueries.CreateRide(ctx, databasepostgres.CreateRideParams{
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
		return domain.Ride{}, passengerActiveRideConflictError("create ride", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Ride{}, passengerActiveRideConflictError("commit created ride", err)
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

func rideRating(value float64) pgtype.Float8 {
	if value <= 0 {
		return pgtype.Float8{}
	}
	return pgtype.Float8{Float64: value, Valid: true}
}

func rideText(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}
