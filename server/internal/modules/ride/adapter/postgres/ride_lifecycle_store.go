package postgres

import (
	"context"
	"errors"
	"fmt"
	ports "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"strconv"
	"time"
)

var _ ports.RideLifecycleStore = (*RideRepository)(nil)

func (repository *RideRepository) MarkArrived(
	ctx context.Context,
	rideID int,
	driverID int,
	currentStatus string,
	passengerWaitDuration time.Duration,
) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	current, ok := domain.NormalizeRideStatus(currentStatus)
	if !ok || (current != domain.RideAssigned && current != domain.RideAccepted) {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	dbRideID, err := pgutil.ToPositiveInt32(rideID, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	dbDriverID, err := pgutil.ToPositiveInt32(driverID, "driver id")
	if err != nil {
		return domain.Ride{}, err
	}
	waitSeconds, err := toPostgresWaitSeconds(passengerWaitDuration)
	if err != nil {
		return domain.Ride{}, err
	}
	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin ride arrival transaction: %w", err)
	}
	defer platformdatabase.Rollback(ctx, transaction)
	transactionQueries := repository.queries.WithTx(transaction)
	_, err = transactionQueries.MarkRideArrived(ctx, databasepostgres.MarkRideArrivedParams{
		RideID:        dbRideID,
		DriverID:      pgtype.Int4{Int32: dbDriverID, Valid: true},
		CurrentStatus: string(current),
		WaitSeconds:   waitSeconds,
	})
	if err != nil {
		mapped := fmt.Errorf("mark ride arrived: %w", err)
		if errors.Is(err, pgx.ErrNoRows) {
			mapped = classifyRideCommandMismatch(ctx, transactionQueries, dbRideID, dbDriverID, true)
		}
		return domain.Ride{}, rollbackRideStatusTransaction(ctx, transaction, mapped)
	}
	requestID, err := newAuditRequestID()
	if err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("create ride arrival request id: %w", err),
		)
	}
	if err := transactionQueries.CreateRideEvent(ctx, databasepostgres.CreateRideEventParams{
		RideID:     dbRideID,
		ActorID:    dbDriverID,
		EventType:  domain.RideEventStatusChanged,
		FromStatus: string(current),
		ToStatus:   string(domain.RideArrived),
		RequestID:  requestID,
	}); err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("create ride arrival event: %w", err),
		)
	}
	return commitRideProjection(
		ctx,
		transaction,
		transactionQueries,
		dbRideID,
		"read arrived ride",
		"commit ride arrival transaction",
	)
}

func (repository *RideRepository) StartTrip(
	ctx context.Context,
	rideID int,
	driverID int,
) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	dbRideID, err := pgutil.ToPositiveInt32(rideID, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	dbDriverID, err := pgutil.ToPositiveInt32(driverID, "driver id")
	if err != nil {
		return domain.Ride{}, err
	}
	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin trip start transaction: %w", err)
	}
	defer platformdatabase.Rollback(ctx, transaction)
	transactionQueries := repository.queries.WithTx(transaction)
	_, err = transactionQueries.StartRide(ctx, databasepostgres.StartRideParams{
		RideID:   dbRideID,
		DriverID: pgtype.Int4{Int32: dbDriverID, Valid: true},
	})
	if err != nil {
		mapped := fmt.Errorf("start ride: %w", err)
		if errors.Is(err, pgx.ErrNoRows) {
			mapped = classifyRideCommandMismatch(ctx, transactionQueries, dbRideID, dbDriverID, true)
		}
		return domain.Ride{}, rollbackRideStatusTransaction(ctx, transaction, mapped)
	}
	return repository.commitLifecycleCommand(
		ctx,
		transaction,
		transactionQueries,
		dbRideID,
		dbDriverID,
		domain.RideArrived,
		domain.RideInTransit,
		"ride.started",
	)
}

func (repository *RideRepository) CompleteTrip(
	ctx context.Context,
	rideID int,
	driverID int,
) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	dbRideID, err := pgutil.ToPositiveInt32(rideID, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	dbDriverID, err := pgutil.ToPositiveInt32(driverID, "driver id")
	if err != nil {
		return domain.Ride{}, err
	}
	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin trip completion transaction: %w", err)
	}
	defer platformdatabase.Rollback(ctx, transaction)
	transactionQueries := repository.queries.WithTx(transaction)
	_, err = transactionQueries.CompleteRide(ctx, databasepostgres.CompleteRideParams{
		RideID:   dbRideID,
		DriverID: pgtype.Int4{Int32: dbDriverID, Valid: true},
	})
	if err != nil {
		mapped := fmt.Errorf("complete ride: %w", err)
		if errors.Is(err, pgx.ErrNoRows) {
			mapped = classifyRideCommandMismatch(ctx, transactionQueries, dbRideID, dbDriverID, true)
		}
		return domain.Ride{}, rollbackRideStatusTransaction(ctx, transaction, mapped)
	}
	return repository.commitLifecycleCommand(
		ctx,
		transaction,
		transactionQueries,
		dbRideID,
		dbDriverID,
		domain.RideInTransit,
		domain.RideCompleted,
		"ride.completed",
	)
}

func (repository *RideRepository) MarkPassengerNoShow(
	ctx context.Context,
	rideID int,
	driverID int,
) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	dbRideID, err := pgutil.ToPositiveInt32(rideID, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	dbDriverID, err := pgutil.ToPositiveInt32(driverID, "driver id")
	if err != nil {
		return domain.Ride{}, err
	}
	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin passenger no-show transaction: %w", err)
	}
	defer platformdatabase.Rollback(ctx, transaction)
	transactionQueries := repository.queries.WithTx(transaction)
	_, err = transactionQueries.MarkRidePassengerNoShow(ctx, databasepostgres.MarkRidePassengerNoShowParams{
		DriverID: pgtype.Int4{Int32: dbDriverID, Valid: true},
		RideID:   dbRideID,
	})
	if err != nil {
		mapped := domain.ErrPassengerNoShowNotReady
		if !errors.Is(err, pgx.ErrNoRows) {
			mapped = fmt.Errorf("mark passenger no-show: %w", err)
		}
		return domain.Ride{}, rollbackRideStatusTransaction(ctx, transaction, mapped)
	}
	requestID, err := newAuditRequestID()
	if err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("create passenger no-show request id: %w", err),
		)
	}
	if err := transactionQueries.CreateRideEvent(ctx, databasepostgres.CreateRideEventParams{
		RideID:         dbRideID,
		ActorID:        dbDriverID,
		EventType:      domain.RideEventCancelled,
		FromStatus:     string(domain.RideArrived),
		ToStatus:       string(domain.RideCancelled),
		Reason:         string(domain.CancellationReasonPassengerNoShow),
		Responsibility: string(domain.CancellationResponsibilityPassengerFault),
		Details:        "Driver completed the server-enforced pickup wait.",
		RequestID:      requestID,
	}); err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("create passenger no-show event: %w", err),
		)
	}
	if _, err := transactionQueries.CreateAuditEvent(ctx, databasepostgres.CreateAuditEventParams{
		ActorID:    dbDriverID,
		Action:     "ride.passenger_no_show",
		TargetType: "ride",
		TargetID:   pgtype.Text{String: strconv.FormatInt(int64(rideID), 10), Valid: true},
		Outcome:    "success",
		RequestID:  requestID + "-audit",
	}); err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("create passenger no-show audit event: %w", err),
		)
	}
	return commitRideProjection(
		ctx,
		transaction,
		transactionQueries,
		dbRideID,
		"read passenger no-show ride",
		"commit passenger no-show transaction",
	)
}

func (repository *RideRepository) commitLifecycleCommand(
	ctx context.Context,
	transaction pgx.Tx,
	transactionQueries *databasepostgres.Queries,
	rideID int32,
	driverID int32,
	fromStatus domain.RideStatus,
	toStatus domain.RideStatus,
	auditAction string,
) (domain.Ride, error) {
	requestID, err := newAuditRequestID()
	if err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("create lifecycle request id: %w", err),
		)
	}
	if err := transactionQueries.CreateRideEvent(ctx, databasepostgres.CreateRideEventParams{
		RideID:     rideID,
		ActorID:    driverID,
		EventType:  domain.RideEventStatusChanged,
		FromStatus: string(fromStatus),
		ToStatus:   string(toStatus),
		RequestID:  requestID,
	}); err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("create lifecycle event: %w", err),
		)
	}
	if _, err := transactionQueries.CreateAuditEvent(ctx, databasepostgres.CreateAuditEventParams{
		ActorID:    driverID,
		Action:     auditAction,
		TargetType: "ride",
		TargetID:   pgtype.Text{String: strconv.FormatInt(int64(rideID), 10), Valid: true},
		Outcome:    "success",
		RequestID:  requestID + "-audit",
	}); err != nil {
		return domain.Ride{}, rollbackRideStatusTransaction(
			ctx,
			transaction,
			fmt.Errorf("create lifecycle audit event: %w", err),
		)
	}
	return commitRideProjection(
		ctx,
		transaction,
		transactionQueries,
		rideID,
		"read lifecycle ride",
		"commit lifecycle transaction",
	)
}
