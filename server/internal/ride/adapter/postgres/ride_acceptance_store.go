package postgres

import (
	"context"
	"fmt"
	"time"

	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

const rideAcceptanceStatementTimeout = 3 * time.Second

func (repository *RideRepository) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	dbRideID, err := toPostgresRideID(rideID, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	dbDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return domain.Ride{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin ride acceptance transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()
	if _, err := transaction.Exec(
		ctx,
		"SELECT set_config('statement_timeout', $1, true)",
		rideAcceptanceStatementTimeout.String(),
	); err != nil {
		return domain.Ride{}, fmt.Errorf("configure ride acceptance statement timeout: %w", err)
	}

	transactionQueries := repository.queries.WithTx(transaction)
	profile, err := transactionQueries.LockOnlineDriverProfileForBidding(ctx, dbDriverID)
	if err != nil {
		return domain.Ride{}, driverUnavailableError("lock online driver profile for ride acceptance", err)
	}
	activeRides, err := transactionQueries.CountActiveRidesForAcceptance(
		ctx,
		pgtype.Int4{Int32: profile.UserID, Valid: true},
	)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("count active driver rides: %w", err)
	}
	if activeRides > 0 {
		return domain.Ride{}, domain.ErrDriverHasActiveRide
	}
	trip, err := transactionQueries.LockRequestedRideForAcceptance(ctx, dbRideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("find requested ride: %w", err)
	}
	settlement, err := domain.NewSettlementSnapshot(
		trip.FareAmount,
		repository.platformCommissionBPS,
	)
	if err != nil {
		return domain.Ride{}, err
	}
	updatedRide, err := transactionQueries.AcceptRideFromRequest(ctx, databasepostgres.AcceptRideFromRequestParams{
		ID:                 trip.ID,
		DriverID:           pgtype.Int4{Int32: profile.UserID, Valid: true},
		DriverName:         rideText(profile.Name),
		VehicleType:        rideText(profile.VehicleType),
		PlateNumber:        rideText(profile.PlateNumber),
		CommissionBps:      pgtype.Int4{Int32: int32(settlement.CommissionBPS), Valid: true},
		CommissionAmount:   settlement.CommissionAmount,
		DriverPayoutAmount: settlement.DriverPayoutAmount,
	})
	if err != nil {
		return domain.Ride{}, driverActiveRideConflictError("accept ride", err)
	}
	if err := transactionQueries.CreateRideSettlement(ctx, databasepostgres.CreateRideSettlementParams{
		RideID:             updatedRide.ID,
		GrossFare:          settlement.FareAmount,
		CommissionBps:      pgtype.Int4{Int32: int32(settlement.CommissionBPS), Valid: true},
		CommissionAmount:   settlement.CommissionAmount,
		DriverPayoutAmount: settlement.DriverPayoutAmount,
	}); err != nil {
		return domain.Ride{}, fmt.Errorf("create ride settlement: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Ride{}, fmt.Errorf("commit ride acceptance transaction: %w", err)
	}
	ride, err := fromPostgresRide(updatedRide)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("map accepted ride: %w", err)
	}
	return ride, nil
}
