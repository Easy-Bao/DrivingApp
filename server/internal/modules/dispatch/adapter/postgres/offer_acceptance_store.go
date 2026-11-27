package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	dispatchapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (repository *Store) AcceptOffer(
	ctx context.Context,
	sessionID int,
	offerID int,
	passengerID int,
) (dispatchapp.OfferAcceptance, error) {
	if err := repository.validate(); err != nil {
		return dispatchapp.OfferAcceptance{}, err
	}
	dbSessionID, err := pgutil.ToPositiveInt32(sessionID, "session id")
	if err != nil {
		return dispatchapp.OfferAcceptance{}, err
	}
	dbOfferID, err := pgutil.ToPositiveInt32(offerID, "offer id")
	if err != nil {
		return dispatchapp.OfferAcceptance{}, err
	}
	dbPassengerID, err := pgutil.ToPositiveInt32(passengerID, "passenger id")
	if err != nil {
		return dispatchapp.OfferAcceptance{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("begin offer acceptance transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	session, err := transactionQueries.LockActiveBidSessionForOffer(
		ctx,
		databasepostgres.LockActiveBidSessionForOfferParams{
			ID:        dbSessionID,
			ExpiresAt: pgutil.ToTimestamptz(time.Now().UTC()),
		},
	)
	if err != nil {
		if replay, ok := acceptedOfferReplay(ctx, transactionQueries, dbSessionID, dbOfferID, dbPassengerID); ok {
			return replay, nil
		}
		if errors.Is(err, pgx.ErrNoRows) {
			return dispatchapp.OfferAcceptance{}, classifyMissingActiveSessionForAcceptance(
				ctx,
				transactionQueries,
				dbSessionID,
				dbPassengerID,
			)
		}
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("find active bid session: %w", err)
	}
	if session.PassengerID != dbPassengerID {
		return dispatchapp.OfferAcceptance{}, dispatchdomain.ErrUnauthorizedSession
	}
	// Resolve the immutable driver ID without locking the offer, then serialize
	// all acceptances for that driver before locking any pending offer rows. This
	// ordering prevents two sessions from deadlocking while each withdraws the
	// other session's outstanding offer.
	offerDriverID, err := transactionQueries.GetBidOfferDriverForAcceptance(
		ctx,
		databasepostgres.GetBidOfferDriverForAcceptanceParams{
			ID:        dbOfferID,
			SessionID: dbSessionID,
		},
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return dispatchapp.OfferAcceptance{}, dispatchdomain.ErrOfferNotFound
		}
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("find bid offer driver: %w", err)
	}
	profile, err := transactionQueries.LockOnlineDriverProfileForBidding(
		ctx,
		databasepostgres.LockOnlineDriverProfileForBiddingParams{
			UserID:                     offerDriverID,
			OnlineCutoff:               repository.onlinePresenceCutoff(),
			AllowUnverifiedTestDrivers: repository.allowUnverifiedTestDrivers,
		},
	)
	if err != nil {
		return dispatchapp.OfferAcceptance{}, driverUnavailableError(
			"lock online driver profile for offer acceptance",
			err,
			dispatchdomain.ErrDriverUnavailable,
		)
	}
	offer, err := transactionQueries.LockPendingBidOfferForAcceptance(
		ctx,
		databasepostgres.LockPendingBidOfferForAcceptanceParams{
			ID:        dbOfferID,
			SessionID: dbSessionID,
		},
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return dispatchapp.OfferAcceptance{}, dispatchdomain.ErrOfferNotFound
		}
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("find pending bid offer: %w", err)
	}
	if session.TargetDriverID.Valid && session.TargetDriverID.Int32 != offer.DriverID {
		return dispatchapp.OfferAcceptance{}, dispatchdomain.ErrUnauthorizedSession
	}
	if profile.UserID != offer.DriverID {
		return dispatchapp.OfferAcceptance{}, dispatchdomain.ErrUnauthorizedSession
	}
	activeDriverRides, err := transactionQueries.CountActiveRidesForAcceptance(
		ctx,
		pgtype.Int4{Int32: profile.UserID, Valid: true},
	)
	if err != nil {
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("count active driver rides: %w", err)
	}
	if activeDriverRides >= domain.MaxActiveRidesPerDriver {
		return dispatchapp.OfferAcceptance{}, domain.ErrDriverCapacityReached
	}
	activePassengerRide, err := transactionQueries.HasActivePassengerRide(ctx, session.PassengerID)
	if err != nil {
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("check active passenger ride: %w", err)
	}
	if activePassengerRide {
		return dispatchapp.OfferAcceptance{}, domain.ErrActiveBooking
	}
	updatedOffer, err := transactionQueries.MarkBidOfferAccepted(ctx, offer.ID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return dispatchapp.OfferAcceptance{}, dispatchdomain.ErrSessionClosed
		}
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("accept bid offer: %w", err)
	}
	rejectedRows, err := transactionQueries.RejectOtherPendingBidOffers(ctx, databasepostgres.RejectOtherPendingBidOffersParams{
		SessionID: session.ID,
		ID:        offer.ID,
	})
	if err != nil {
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("reject competing bid offers: %w", err)
	}
	rejectedOffers := make([]dispatchdomain.BidOffer, 0, len(rejectedRows))
	for _, row := range rejectedRows {
		rejectedOffer, mappingErr := fromPostgresBidOffer(row)
		if mappingErr != nil {
			return dispatchapp.OfferAcceptance{}, fmt.Errorf("map rejected competing bid offer: %w", mappingErr)
		}
		rejectedOffers = append(rejectedOffers, rejectedOffer)
	}
	var withdrawnOffers []dispatchdomain.BidOfferWithdrawal
	if activeDriverRides+1 >= domain.MaxActiveRidesPerDriver {
		withdrawnRows, err := transactionQueries.RejectDriverPendingBidOffers(
			ctx,
			databasepostgres.RejectDriverPendingBidOffersParams{DriverID: offer.DriverID, ID: offer.ID},
		)
		if err != nil {
			return dispatchapp.OfferAcceptance{}, fmt.Errorf("reject driver's outstanding offers: %w", err)
		}
		withdrawnOffers, err = mapBidOfferWithdrawals(withdrawnRows)
		if err != nil {
			return dispatchapp.OfferAcceptance{}, err
		}
	}
	updatedSession, err := transactionQueries.MarkBidSessionAccepted(ctx, databasepostgres.MarkBidSessionAcceptedParams{
		ID:               session.ID,
		AcceptedDriverID: pgtype.Int4{Int32: offer.DriverID, Valid: true},
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return dispatchapp.OfferAcceptance{}, dispatchdomain.ErrSessionClosed
		}
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("accept bid session: %w", err)
	}
	createdRide, settlementRecord, err := createAcceptedRideAndSettlement(
		ctx,
		transactionQueries,
		session,
		profile,
		offer,
		repository.platformCommissionBPS,
	)
	if err != nil {
		return dispatchapp.OfferAcceptance{}, err
	}
	if err := transaction.Commit(ctx); err != nil {
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("commit offer acceptance transaction: %w", err)
	}
	resultSession, err := fromPostgresBidSession(updatedSession)
	if err != nil {
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("map accepted bid session: %w", err)
	}
	resultOffer, err := fromPostgresBidOffer(updatedOffer)
	if err != nil {
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("map accepted bid offer: %w", err)
	}
	resultRide, err := fromPostgresAcceptedRideProjection(createdRide, settlementRecord)
	if err != nil {
		return dispatchapp.OfferAcceptance{}, fmt.Errorf("map accepted ride: %w", err)
	}
	return dispatchapp.OfferAcceptance{
		Session:         resultSession,
		Offer:           resultOffer,
		Ride:            resultRide,
		RejectedOffers:  rejectedOffers,
		WithdrawnOffers: withdrawnOffers,
	}, nil
}

func classifyMissingActiveSessionForAcceptance(
	ctx context.Context,
	queries *databasepostgres.Queries,
	dbSessionID, dbPassengerID int32,
) error {
	existingSession, err := queries.GetBidSessionByID(ctx, dbSessionID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return dispatchdomain.ErrSessionNotFound
		}
		return fmt.Errorf("load bid session state: %w", err)
	}
	if existingSession.PassengerID != dbPassengerID {
		return dispatchdomain.ErrUnauthorizedSession
	}
	return dispatchdomain.ErrSessionClosed
}

func acceptedOfferReplay(
	ctx context.Context,
	queries *databasepostgres.Queries,
	dbSessionID, dbOfferID, dbPassengerID int32,
) (dispatchapp.OfferAcceptance, bool) {
	existingSession, err := queries.GetBidSessionByID(ctx, dbSessionID)
	if err != nil || existingSession.Status != "accepted" || existingSession.PassengerID != dbPassengerID || !existingSession.AcceptedDriverID.Valid {
		return dispatchapp.OfferAcceptance{}, false
	}
	offers, err := queries.ListBidOffersBySession(ctx, dbSessionID)
	if err != nil {
		return dispatchapp.OfferAcceptance{}, false
	}
	for _, candidateOffer := range offers {
		if candidateOffer.ID != dbOfferID || candidateOffer.Status != "accepted" || existingSession.AcceptedDriverID.Int32 != candidateOffer.DriverID {
			continue
		}
		sessionRideRow, rideErr := queries.GetRideByBidSessionID(ctx, pgtype.Int4{Int32: dbSessionID, Valid: true})
		if rideErr != nil {
			return dispatchapp.OfferAcceptance{}, false
		}
		sessionValue, sessionErr := fromPostgresBidSession(existingSession)
		offerValue, offerErr := fromPostgresBidOffer(candidateOffer)
		rideValue, mapRideErr := fromPostgresBidSessionRideRow(sessionRideRow)
		if sessionErr != nil || offerErr != nil || mapRideErr != nil {
			return dispatchapp.OfferAcceptance{}, false
		}
		return dispatchapp.OfferAcceptance{
			Session:  sessionValue,
			Offer:    offerValue,
			Ride:     rideValue,
			Replayed: true,
		}, true
	}
	return dispatchapp.OfferAcceptance{}, false
}

func createAcceptedRideAndSettlement(
	ctx context.Context,
	queries *databasepostgres.Queries,
	session databasepostgres.BidSession,
	profile databasepostgres.LockOnlineDriverProfileForBiddingRow,
	offer databasepostgres.BidOffer,
	platformCommissionBPS int64,
) (databasepostgres.Ride, databasepostgres.RideSettlement, error) {
	sessionValue, err := fromPostgresBidSession(session)
	if err != nil {
		return databasepostgres.Ride{}, databasepostgres.RideSettlement{}, fmt.Errorf("map bid session for offer acceptance: %w", err)
	}
	offerValue, err := fromPostgresBidOffer(offer)
	if err != nil {
		return databasepostgres.Ride{}, databasepostgres.RideSettlement{}, fmt.Errorf("map bid offer for offer acceptance: %w", err)
	}
	if sessionValue.ID <= 0 || sessionValue.PassengerID <= 0 ||
		offerValue.DriverID <= 0 || offerValue.SessionID != sessionValue.ID {
		return databasepostgres.Ride{}, databasepostgres.RideSettlement{}, domain.ErrInvalidTrip
	}
	driverID := offerValue.DriverID
	acceptedRide, err := domain.NewAcceptedRide(
		domain.Ride{
			PassengerID:      sessionValue.PassengerID,
			DriverID:         &driverID,
			FareAmount:       offerValue.ProposedFareAmount,
			PickupLatitude:   sessionValue.PickupLatitude,
			PickupLongitude:  sessionValue.PickupLongitude,
			PickupName:       sessionValue.PickupName,
			DropoffLatitude:  sessionValue.DropoffLatitude,
			DropoffLongitude: sessionValue.DropoffLongitude,
			DropoffName:      sessionValue.DropoffName,
			DistanceKm:       sessionValue.DistanceKm,
			DurationMinutes:  sessionValue.DurationMinutes,
		},
		domain.DriverAssignmentSnapshot{
			Name:        profile.Name,
			VehicleType: profile.VehicleType,
			PlateNumber: profile.PlateNumber,
			Rating:      profile.Rating,
		},
		platformCommissionBPS,
	)
	if err != nil {
		return databasepostgres.Ride{}, databasepostgres.RideSettlement{}, err
	}
	if acceptedRide.DriverID == nil || acceptedRide.CommissionBPS == nil {
		return databasepostgres.Ride{}, databasepostgres.RideSettlement{}, domain.ErrInvalidSettlement
	}
	dbAcceptedDriverID, err := pgutil.ToPositiveInt32(*acceptedRide.DriverID, "driver id")
	if err != nil {
		return databasepostgres.Ride{}, databasepostgres.RideSettlement{}, err
	}
	createdRide, err := queries.CreateAcceptedRide(ctx, databasepostgres.CreateAcceptedRideParams{
		PassengerID:      session.PassengerID,
		DriverID:         pgtype.Int4{Int32: dbAcceptedDriverID, Valid: true},
		FareAmount:       acceptedRide.FareAmount,
		PickupLatitude:   rideFloat(acceptedRide.PickupLatitude),
		PickupLongitude:  rideFloat(acceptedRide.PickupLongitude),
		PickupName:       pgutil.ToText(acceptedRide.PickupName),
		DropoffLatitude:  rideFloat(acceptedRide.DropoffLatitude),
		DropoffLongitude: rideFloat(acceptedRide.DropoffLongitude),
		DropoffName:      pgutil.ToText(acceptedRide.DropoffName),
		DistanceKm:       rideFloat(acceptedRide.DistanceKm),
		DurationMinutes:  rideFloat(acceptedRide.DurationMinutes),
		DriverName:       pgutil.ToText(acceptedRide.DriverName),
		VehicleType:      pgutil.ToText(acceptedRide.VehicleType),
		PlateNumber:      pgutil.ToText(acceptedRide.PlateNumber),
		DriverRating:     rideRating(acceptedRide.DriverRating),
		BidSessionID:     pgtype.Int4{Int32: session.ID, Valid: true},
	})
	if err != nil {
		return databasepostgres.Ride{}, databasepostgres.RideSettlement{}, acceptedRideConflictError("create accepted ride", err)
	}
	settlementRecord, err := queries.CreateRideSettlement(ctx, databasepostgres.CreateRideSettlementParams{
		RideID:             createdRide.ID,
		GrossFare:          acceptedRide.FareAmount,
		CommissionBps:      pgtype.Int4{Int32: int32(*acceptedRide.CommissionBPS), Valid: true},
		CommissionAmount:   acceptedRide.CommissionAmount,
		DriverPayoutAmount: acceptedRide.DriverPayoutAmount,
	})
	if err != nil {
		return databasepostgres.Ride{}, databasepostgres.RideSettlement{}, fmt.Errorf("create ride settlement: %w", err)
	}
	return createdRide, settlementRecord, nil
}

func mapBidOfferWithdrawals(
	rows []databasepostgres.RejectDriverPendingBidOffersRow,
) ([]dispatchdomain.BidOfferWithdrawal, error) {
	withdrawals := make([]dispatchdomain.BidOfferWithdrawal, 0, len(rows))
	for _, item := range rows {
		// The offer columns come from the UPDATE's RETURNING relation so the
		// payload carries the rejected status rather than the pre-update row.
		offer, err := fromPostgresBidOffer(databasepostgres.BidOffer{
			ID:           item.OfferID,
			SessionID:    item.OfferSessionID,
			DriverID:     item.OfferDriverID,
			DriverName:   item.OfferDriverName,
			PlateNumber:  item.OfferPlateNumber,
			VehicleType:  item.OfferVehicleType,
			ProposedFare: item.OfferProposedFare,
			Status:       item.OfferStatus,
			CreatedAt:    item.OfferCreatedAt,
		})
		if err != nil {
			return nil, fmt.Errorf("map withdrawn bid offer: %w", err)
		}
		session, err := fromPostgresBidSession(item.BidSession)
		if err != nil {
			return nil, fmt.Errorf("map withdrawn offer session: %w", err)
		}
		withdrawals = append(withdrawals, dispatchdomain.BidOfferWithdrawal{
			Session: session,
			Offer:   offer,
		})
	}
	return withdrawals, nil
}
