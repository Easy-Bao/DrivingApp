package postgres

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"strconv"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var _ ports.RideLifecycleStore = (*RideRepository)(nil)

func (repository *RideRepository) UpdateStatus(
	ctx context.Context,
	rideID int,
	actorID int,
	currentStatus string,
	status string,
) (domain.Ride, error) {
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
	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin ride status transaction: %w", err)
	}
	transactionQueries := repository.queries.WithTx(transaction)
	item, err := transactionQueries.UpdateRideStatus(ctx, databasepostgres.UpdateRideStatusParams{
		NextStatus:    string(next),
		CompletedAt:   completedAt,
		RideID:        dbRideID,
		CurrentStatus: string(current),
		ActorID:       dbActorID,
	})
	if err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("update ride status: %w", err),
		)
	}
	if next == domain.RideCancelled {
		requestID, requestIDErr := newAuditRequestID()
		if requestIDErr != nil {
			return domain.Ride{}, rollbackRideStatusTransaction(
				ctx,
				transaction,
				fmt.Errorf("create cancellation audit request id: %w", requestIDErr),
			)
		}
		if _, err := transactionQueries.CreateAuditEvent(ctx, databasepostgres.CreateAuditEventParams{
			ActorID:    dbActorID,
			Action:     "ride.cancelled",
			TargetType: "ride",
			TargetID:   pgtype.Text{String: strconv.Itoa(rideID), Valid: true},
			Outcome:    "success",
			RequestID:  requestID,
		}); err != nil {
			return domain.Ride{}, rollbackRideStatusTransaction(
				ctx,
				transaction,
				fmt.Errorf("create cancellation audit event: %w", err),
			)
		}
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("commit ride status transaction: %w", err),
		)
	}
	ride, err := fromPostgresRide(item)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("map updated ride: %w", err)
	}
	return ride, nil
}

func rollbackRideStatusTransaction(
	ctx context.Context,
	transaction pgx.Tx,
	cause error,
) error {
	if rollbackErr := transaction.Rollback(ctx); rollbackErr != nil &&
		!errors.Is(rollbackErr, pgx.ErrTxClosed) {
		return errors.Join(
			cause,
			fmt.Errorf("rollback ride status transaction: %w", rollbackErr),
		)
	}
	return cause
}

func newAuditRequestID() (string, error) {
	var value [16]byte
	if _, err := rand.Read(value[:]); err != nil {
		return "", fmt.Errorf("generate audit request id: %w", err)
	}
	return hex.EncodeToString(value[:]), nil
}
