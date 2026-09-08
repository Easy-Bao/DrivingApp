package postgres

import (
	"context"
	"fmt"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

func (repository *PostgresRideRepository) CreateRide(ctx context.Context, value domain.Ride) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	if value.PassengerID <= 0 || value.FareCentavos <= 0 {
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
	item, err := repository.queries.CreateRide(ctx, databasepostgres.CreateRideParams{
		PassengerID:      passengerID,
		Status:           string(normalizedStatus),
		FareCentavos:     value.FareCentavos,
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
		return domain.Ride{}, fmt.Errorf("create ride: %w", err)
	}
	return fromPostgresRide(item)
}

func (repository *PostgresRideRepository) CreateBid(ctx context.Context, value domain.Bid) (domain.Bid, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Bid{}, err
	}
	if value.RideID <= 0 || value.DriverID <= 0 || value.FareCentavos <= 0 {
		return domain.Bid{}, domain.ErrInvalidFareOffer
	}
	if value.Status == "" {
		value.Status = "pending"
	}
	if value.Status != "pending" {
		return domain.Bid{}, domain.ErrInvalidFareOffer
	}
	rideID, err := toPostgresRideID(value.RideID, "ride id")
	if err != nil {
		return domain.Bid{}, err
	}
	driverID, err := toPostgresRideID(value.DriverID, "driver id")
	if err != nil {
		return domain.Bid{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Bid{}, fmt.Errorf("begin bid transaction: %w", err)
	}
	defer func() {
		_ = transaction.Rollback(ctx)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	if _, err := transactionQueries.LockOnlineDriverProfileForBidding(ctx, driverID); err != nil {
		return domain.Bid{}, domain.ErrDriverUnavailable
	}
	if _, err := transactionQueries.LockRequestedRideForBid(ctx, rideID); err != nil {
		return domain.Bid{}, domain.ErrDriverUnavailable
	}
	exists, err := transactionQueries.HasPendingBid(ctx, databasepostgres.HasPendingBidParams{
		RideID:   rideID,
		DriverID: driverID,
	})
	if err != nil {
		return domain.Bid{}, fmt.Errorf("check duplicate bid: %w", err)
	}
	if exists {
		return domain.Bid{}, domain.ErrDuplicateBid
	}
	item, err := transactionQueries.CreateBid(ctx, databasepostgres.CreateBidParams{
		RideID:              rideID,
		DriverID:            driverID,
		OfferedFareCentavos: value.FareCentavos,
		Status:              value.Status,
	})
	if err != nil {
		if isPostgresBiddingUniqueViolation(err) {
			return domain.Bid{}, domain.ErrDuplicateBid
		}
		return domain.Bid{}, fmt.Errorf("create bid: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Bid{}, fmt.Errorf("commit bid transaction: %w", err)
	}
	return fromPostgresBid(item), nil
}

func fromPostgresBid(item databasepostgres.Bid) domain.Bid {
	return domain.Bid{
		ID:           int(item.ID),
		RideID:       int(item.RideID),
		DriverID:     int(item.DriverID),
		FareCentavos: item.OfferedFareCentavos,
		Status:       item.Status,
	}
}

func rideFloat(value float64) pgtype.Float8 {
	return pgtype.Float8{Float64: value, Valid: true}
}

func rideText(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}
