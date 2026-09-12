package postgres

import (
	"context"
	"fmt"

	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

func (repository *RideRepository) AcceptBid(ctx context.Context, bidID, driverID int) (domain.Bid, domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	dbBidID, err := toPostgresRideID(bidID, "bid id")
	if err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	dbDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, fmt.Errorf("begin bid acceptance transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	offer, err := transactionQueries.LockPendingBidForAcceptance(ctx, databasepostgres.LockPendingBidForAcceptanceParams{
		ID:       dbBidID,
		DriverID: dbDriverID,
	})
	if err != nil {
		return domain.Bid{}, domain.Ride{}, fmt.Errorf("find pending bid: %w", err)
	}
	profile, err := transactionQueries.LockOnlineDriverProfileForBidding(ctx, dbDriverID)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, driverUnavailableError("lock online driver profile for bid acceptance", err)
	}
	activeRides, err := transactionQueries.CountActiveRidesForAcceptance(
		ctx,
		pgtype.Int4{Int32: profile.UserID, Valid: true},
	)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, fmt.Errorf("count active driver rides: %w", err)
	}
	if activeRides >= 5 {
		return domain.Bid{}, domain.Ride{}, domain.ErrDriverAtCapacity
	}
	updatedBid, err := transactionQueries.MarkBidAccepted(ctx, offer.ID)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, fmt.Errorf("accept bid: %w", err)
	}
	trip, err := transactionQueries.LockRequestedRideForAcceptance(ctx, offer.RideID)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, fmt.Errorf("find requested ride: %w", err)
	}
	settlement, err := domain.NewSettlementSnapshot(
		trip.FareCentavos,
		repository.platformCommissionBPS,
	)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	updatedRide, err := transactionQueries.AssignRideFromAcceptance(ctx, databasepostgres.AssignRideFromAcceptanceParams{
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
		return domain.Bid{}, domain.Ride{}, fmt.Errorf("assign ride: %w", err)
	}
	if err := transactionQueries.CreateRideSettlement(ctx, databasepostgres.CreateRideSettlementParams{
		RideID:               updatedRide.ID,
		GrossFareCentavos:    settlement.FareCentavos,
		CommissionBps:        pgtype.Int8{Int64: settlement.CommissionBPS, Valid: true},
		CommissionCentavos:   settlement.CommissionCentavos,
		DriverPayoutCentavos: settlement.DriverPayoutCentavos,
	}); err != nil {
		return domain.Bid{}, domain.Ride{}, fmt.Errorf("create ride settlement: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Bid{}, domain.Ride{}, fmt.Errorf("commit bid acceptance transaction: %w", err)
	}
	resultBid := fromPostgresBid(updatedBid)
	resultRide, err := fromPostgresRide(updatedRide)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, fmt.Errorf("map accepted ride: %w", err)
	}
	return resultBid, resultRide, nil
}
