package postgres

import (
	"context"
	"fmt"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

func (repository *PostgresRideRepository) UpdateStatus(ctx context.Context, rideID, actorID int, currentStatus, status string) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	current, currentOK := domain.NormalizeRideStatus(currentStatus)
	next, nextOK := domain.NormalizeRideStatus(status)
	if !currentOK || !nextOK {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	dbRideID, err := toPostgresRideID(rideID, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	dbActorID, err := toPostgresRideID(actorID, "actor id")
	if err != nil {
		return domain.Ride{}, err
	}
	completedAt := pgtype.Timestamptz{}
	if domain.IsTerminal(string(next)) {
		completedAt = pgtype.Timestamptz{Time: time.Now().UTC(), Valid: true}
	}
	item, err := repository.queries.UpdateRideStatus(ctx, databasepostgres.UpdateRideStatusParams{
		NextStatus:    string(next),
		CompletedAt:   completedAt,
		RideID:        dbRideID,
		CurrentStatus: string(current),
		ActorID:       dbActorID,
	})
	if err != nil {
		return domain.Ride{}, fmt.Errorf("update ride status: %w", err)
	}
	return fromPostgresRide(item)
}
