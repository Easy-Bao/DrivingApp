package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (repository *Store) Offers(ctx context.Context, sessionID int) ([]dispatchdomain.BidOffer, error) {
	if err := repository.validate(); err != nil {
		return nil, err
	}
	dbSessionID, err := pgutil.ToPositiveInt32(sessionID, "session id")
	if err != nil {
		return nil, err
	}
	items, err := repository.queries.ListBidOffersBySession(ctx, dbSessionID)
	if err != nil {
		return nil, fmt.Errorf("list bid offers: %w", err)
	}
	result := make([]dispatchdomain.BidOffer, 0, len(items))
	for _, item := range items {
		offer, mappingErr := fromPostgresBidOffer(item)
		if mappingErr != nil {
			return nil, fmt.Errorf("map bid offer: %w", mappingErr)
		}
		result = append(result, offer)
	}
	return result, nil
}

func (repository *Store) PlaceOffer(ctx context.Context, value dispatchdomain.BidOffer) (dispatchdomain.BidOffer, error) {
	if err := repository.validate(); err != nil {
		return dispatchdomain.BidOffer{}, err
	}
	if value.ProposedFareAmount <= 0 {
		return dispatchdomain.BidOffer{}, dispatchdomain.ErrInvalidFareOffer
	}
	sessionID, err := pgutil.ToPositiveInt32(value.SessionID, "session id")
	if err != nil {
		return dispatchdomain.BidOffer{}, err
	}
	driverID, err := pgutil.ToPositiveInt32(value.DriverID, "driver id")
	if err != nil {
		return dispatchdomain.BidOffer{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return dispatchdomain.BidOffer{}, fmt.Errorf("begin bid offer transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()
	transactionQueries := repository.queries.WithTx(transaction)
	now := pgutil.ToTimestamptz(time.Now().UTC())
	session, err := transactionQueries.LockActiveBidSessionForOffer(
		ctx,
		databasepostgres.LockActiveBidSessionForOfferParams{
			ID:        sessionID,
			ExpiresAt: now,
		},
	)
	if err != nil {
		return dispatchdomain.BidOffer{}, driverUnavailableError(
			"lock active bid session for offer",
			err,
			dispatchdomain.ErrDriverUnavailable,
		)
	}
	if session.TargetDriverID.Valid && session.TargetDriverID.Int32 != driverID {
		return dispatchdomain.BidOffer{}, dispatchdomain.ErrDriverUnavailable
	}
	profile, err := transactionQueries.LockOnlineDriverProfileForBidding(
		ctx,
		databasepostgres.LockOnlineDriverProfileForBiddingParams{
			UserID:                     driverID,
			OnlineCutoff:               repository.onlinePresenceCutoff(),
			AllowUnverifiedTestDrivers: repository.allowUnverifiedTestDrivers,
		},
	)
	if err != nil {
		return dispatchdomain.BidOffer{}, driverUnavailableError(
			"lock online driver profile for offer",
			err,
			dispatchdomain.ErrDriverUnavailable,
		)
	}
	activeRides, err := transactionQueries.CountActiveRidesForDriver(ctx, pgtype.Int4{Int32: profile.UserID, Valid: true})
	if err != nil {
		return dispatchdomain.BidOffer{}, fmt.Errorf("count active driver rides: %w", err)
	}
	if activeRides >= domain.MaxActiveRidesPerDriver {
		return dispatchdomain.BidOffer{}, domain.ErrDriverCapacityReached
	}
	existing, err := transactionQueries.HasPendingBidOffer(ctx, databasepostgres.HasPendingBidOfferParams{
		SessionID: sessionID,
		DriverID:  driverID,
	})
	if err != nil {
		return dispatchdomain.BidOffer{}, fmt.Errorf("check duplicate bid offer: %w", err)
	}
	if existing {
		return dispatchdomain.BidOffer{}, dispatchdomain.ErrDuplicateBid
	}
	created, err := transactionQueries.CreateBidOffer(ctx, databasepostgres.CreateBidOfferParams{
		SessionID:    sessionID,
		DriverID:     driverID,
		DriverName:   pgutil.ToText(profile.Name),
		PlateNumber:  pgutil.ToText(profile.PlateNumber),
		VehicleType:  pgutil.ToText(profile.VehicleType),
		ProposedFare: value.ProposedFareAmount,
	})
	if err != nil {
		if pgutil.IsUniqueViolation(err) {
			return dispatchdomain.BidOffer{}, dispatchdomain.ErrDuplicateBid
		}
		return dispatchdomain.BidOffer{}, fmt.Errorf("create bid offer: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return dispatchdomain.BidOffer{}, fmt.Errorf("commit bid offer transaction: %w", err)
	}
	offer, err := fromPostgresBidOffer(created)
	if err != nil {
		return dispatchdomain.BidOffer{}, fmt.Errorf("map created bid offer: %w", err)
	}
	return offer, nil
}

func (repository *Store) CancelOffer(ctx context.Context, sessionID, driverID int) (dispatchdomain.BidOffer, error) {
	if err := repository.validate(); err != nil {
		return dispatchdomain.BidOffer{}, err
	}
	dbSessionID, err := pgutil.ToPositiveInt32(sessionID, "session id")
	if err != nil {
		return dispatchdomain.BidOffer{}, err
	}
	dbDriverID, err := pgutil.ToPositiveInt32(driverID, "driver id")
	if err != nil {
		return dispatchdomain.BidOffer{}, err
	}
	item, err := repository.queries.CancelPendingBidOffer(ctx, databasepostgres.CancelPendingBidOfferParams{
		SessionID: dbSessionID,
		DriverID:  dbDriverID,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return dispatchdomain.BidOffer{}, dispatchdomain.ErrOfferNotFound
		}
		return dispatchdomain.BidOffer{}, fmt.Errorf("cancel pending bid offer: %w", err)
	}
	offer, err := fromPostgresBidOffer(item)
	if err != nil {
		return dispatchdomain.BidOffer{}, fmt.Errorf("map canceled bid offer: %w", err)
	}
	return offer, nil
}
