package postgres

import (
	"context"
	"fmt"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

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
		_ = transaction.Rollback(ctx)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	profile, err := transactionQueries.LockOnlineDriverProfileForBidding(ctx, dbDriverID)
	if err != nil {
		return domain.Ride{}, domain.ErrDriverUnavailable
	}
	activeRides, err := transactionQueries.CountActiveRidesForAcceptance(ctx, pgtype.Int4{Int32: profile.UserID, Valid: true})
	if err != nil {
		return domain.Ride{}, fmt.Errorf("count active driver rides: %w", err)
	}
	if activeRides >= 5 {
		return domain.Ride{}, domain.ErrDriverAtCapacity
	}
	trip, err := transactionQueries.LockRequestedRideForAcceptance(ctx, dbRideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("find requested ride: %w", err)
	}
	settlement, err := domain.NewSettlementSnapshot(
		trip.FareCentavos,
		repository.platformCommissionBPS,
	)
	if err != nil {
		return domain.Ride{}, err
	}
	updatedRide, err := transactionQueries.AcceptRideFromRequest(ctx, databasepostgres.AcceptRideFromRequestParams{
		ID:                   trip.ID,
		DriverID:             pgtype.Int4{Int32: profile.UserID, Valid: true},
		DriverName:           rideText(profile.Name),
		VehicleType:          rideText(profile.VehicleType),
		PlateNumber:          rideText(profile.PlateNumber),
		CommissionBps:        pgtype.Int8{Int64: settlement.CommissionBPS, Valid: true},
		CommissionCentavos:   settlement.CommissionCentavos,
		DriverPayoutCentavos: settlement.DriverPayoutCentavos,
	})
	if err != nil {
		return domain.Ride{}, fmt.Errorf("accept ride: %w", err)
	}
	if err := transactionQueries.CreateRideSettlement(ctx, databasepostgres.CreateRideSettlementParams{
		RideID:               updatedRide.ID,
		GrossFareCentavos:    settlement.FareCentavos,
		CommissionBps:        pgtype.Int8{Int64: settlement.CommissionBPS, Valid: true},
		CommissionCentavos:   settlement.CommissionCentavos,
		DriverPayoutCentavos: settlement.DriverPayoutCentavos,
	}); err != nil {
		return domain.Ride{}, fmt.Errorf("create ride settlement: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Ride{}, fmt.Errorf("commit ride acceptance transaction: %w", err)
	}
	return fromPostgresRide(updatedRide)
}
