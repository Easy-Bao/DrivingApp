package postgres

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"strconv"
	"time"
)

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
	dbRideID, err := pgutil.ToPositiveInt32(rideID, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	dbActorID, err := pgutil.ToPositiveInt32(actorID, "actor id")
	if err != nil {
		return domain.Ride{}, err
	}
	completedAt := pgtype.Timestamptz{}
	if domain.IsTerminal(string(next)) {
		completedAt = pgutil.ToTimestamptz(time.Now().UTC())
	}
	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin ride status transaction: %w", err)
	}
	defer platformdatabase.Rollback(ctx, transaction)
	transactionQueries := repository.queries.WithTx(transaction)
	_, err = transactionQueries.UpdateRideStatus(ctx, databasepostgres.UpdateRideStatusParams{
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
		mapped := fmt.Errorf("update ride status: %w", err)
		if errors.Is(err, pgx.ErrNoRows) {
			mapped = classifyRideCommandMismatch(ctx, transactionQueries, dbRideID, dbActorID, false)
		}
		return domain.Ride{}, rollbackRideStatusTransaction(ctx, transaction, mapped)
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
		auditAction := "ride.cancelled"
		if transition.EventType == domain.RideEventEmergencyStopped {
			auditAction = "ride.emergency_stopped"
		}
		if _, err := transactionQueries.CreateAuditEvent(ctx, databasepostgres.CreateAuditEventParams{
			ActorID:    dbActorID,
			Action:     auditAction,
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
	return commitRideProjection(
		ctx,
		transaction,
		transactionQueries,
		dbRideID,
		"read updated ride",
		"commit ride status transaction",
	)
}

func commitRideProjection(
	ctx context.Context,
	transaction pgx.Tx,
	queries *databasepostgres.Queries,
	rideID int32,
	readContext string,
	commitContext string,
) (domain.Ride, error) {
	ride, err := readRideProjection(ctx, queries, rideID)
	if err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("%s: %w", readContext, err),
		)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("%s: %w", commitContext, err),
		)
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

func classifyRideCommandMismatch(
	ctx context.Context,
	queries *databasepostgres.Queries,
	rideID int32,
	actorID int32,
	driverOnly bool,
) error {
	existing, err := queries.GetRideByID(ctx, rideID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.ErrRideNotFound
		}
		return fmt.Errorf("check ride state after empty update: %w", err)
	}
	isDriver := existing.Ride.DriverID.Valid && existing.Ride.DriverID.Int32 == actorID
	isPassenger := existing.Ride.PassengerID == actorID
	if driverOnly && !isDriver {
		return domain.ErrUnauthorizedRide
	}
	if !driverOnly && !isDriver && !isPassenger {
		return domain.ErrUnauthorizedRide
	}
	return domain.ErrInvalidStatusTransition
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
