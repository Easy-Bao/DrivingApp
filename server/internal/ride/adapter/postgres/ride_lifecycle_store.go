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
	transition domain.RideTransition,
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
		NextStatus:                 string(next),
		CancelledBy:                cancellationActorID(next, dbActorID),
		CancellationReason:         cancellationText(next, string(transition.Reason)),
		CancellationResponsibility: cancellationText(next, string(transition.Responsibility)),
		CancellationDetails:        cancellationText(next, transition.Details),
		CompletedAt:                completedAt,
		RideID:                     dbRideID,
		CurrentStatus:              string(current),
		ActorID:                    dbActorID,
	})
	if err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("update ride status: %w", err),
		)
	}
	requestID := transition.RequestID
	if requestID == "" {
		requestID, err = newAuditRequestID()
		if err != nil {
			return domain.Ride{}, rollbackRideStatusTransaction(
				ctx,
				transaction,
				fmt.Errorf("create ride event request id: %w", err),
			)
		}
	}
	if err := transactionQueries.CreateRideEvent(ctx, databasepostgres.CreateRideEventParams{
		RideID:         dbRideID,
		ActorID:        dbActorID,
		EventType:      transitionEventType(next, transition.EventType),
		FromStatus:     string(current),
		ToStatus:       string(next),
		Reason:         string(transition.Reason),
		Responsibility: string(transition.Responsibility),
		Details:        transition.Details,
		RequestID:      requestID,
	}); err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("create ride event: %w", err),
		)
	}
	if next == domain.RideCancelled {
		if _, err := transactionQueries.CreateAuditEvent(ctx, databasepostgres.CreateAuditEventParams{
			ActorID:    dbActorID,
			Action:     "ride.cancelled",
			TargetType: "ride",
			TargetID:   pgtype.Text{String: strconv.Itoa(rideID), Valid: true},
			Outcome:    "success",
			RequestID:  requestID + "-audit",
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

func cancellationActorID(status domain.RideStatus, actorID int32) pgtype.Int4 {
	if status != domain.RideCancelled {
		return pgtype.Int4{}
	}
	return pgtype.Int4{Int32: actorID, Valid: true}
}

func cancellationText(status domain.RideStatus, value string) pgtype.Text {
	if status != domain.RideCancelled {
		return pgtype.Text{}
	}
	return pgtype.Text{String: value, Valid: true}
}

func transitionEventType(status domain.RideStatus, requested string) string {
	if requested != "" {
		return requested
	}
	if status == domain.RideCancelled {
		return domain.RideEventCancelled
	}
	return domain.RideEventStatusChanged
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
