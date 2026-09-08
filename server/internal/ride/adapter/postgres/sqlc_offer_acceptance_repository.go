package postgres

import (
	"context"
	"fmt"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

func (repository *PostgresRideRepository) AcceptOffer(ctx context.Context, sessionID, offerID, passengerID int) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	dbOfferID, err := toPostgresRideID(offerID, "offer id")
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	dbPassengerID, err := toPostgresRideID(passengerID, "passenger id")
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("begin offer acceptance transaction: %w", err)
	}
	defer func() {
		_ = transaction.Rollback(ctx)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	session, err := transactionQueries.LockActiveBidSessionForOffer(ctx, databasepostgres.LockActiveBidSessionForOfferParams{
		ID:        dbSessionID,
		ExpiresAt: bidTimestamp(time.Now().UTC()),
	})
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("find active bid session: %w", err)
	}
	if session.PassengerID != dbPassengerID {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	offer, err := transactionQueries.LockPendingBidOfferForAcceptance(ctx, databasepostgres.LockPendingBidOfferForAcceptanceParams{
		ID:        dbOfferID,
		SessionID: dbSessionID,
	})
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("find pending bid offer: %w", err)
	}
	if session.TargetDriverID.Valid && session.TargetDriverID.Int32 != offer.DriverID {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	profile, err := transactionQueries.LockOnlineDriverProfileForBidding(ctx, offer.DriverID)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrDriverUnavailable
	}
	activeDriverRides, err := transactionQueries.CountActiveRidesForAcceptance(ctx, pgtype.Int4{Int32: profile.UserID, Valid: true})
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("count active driver rides: %w", err)
	}
	if activeDriverRides >= 5 {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrDriverAtCapacity
	}
	activePassengerRide, err := transactionQueries.HasActivePassengerRide(ctx, session.PassengerID)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("check active passenger ride: %w", err)
	}
	if activePassengerRide {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrActiveBooking
	}
	updatedOffer, err := transactionQueries.MarkBidOfferAccepted(ctx, offer.ID)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("accept bid offer: %w", err)
	}
	if err := transactionQueries.RejectOtherPendingBidOffers(ctx, databasepostgres.RejectOtherPendingBidOffersParams{
		SessionID: session.ID,
		ID:        offer.ID,
	}); err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("reject competing bid offers: %w", err)
	}
	updatedSession, err := transactionQueries.MarkBidSessionAccepted(ctx, databasepostgres.MarkBidSessionAcceptedParams{
		ID:               session.ID,
		AcceptedDriverID: pgtype.Int4{Int32: offer.DriverID, Valid: true},
	})
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("accept bid session: %w", err)
	}
	sessionValue, err := fromPostgresBidSession(session)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	offerValue, err := fromPostgresBidOffer(offer)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	acceptedRide, err := domain.NewRideFromAcceptedOffer(
		sessionValue,
		offerValue,
		domain.DriverAssignmentSnapshot{
			Name:        profile.Name,
			VehicleType: profile.VehicleType,
			PlateNumber: profile.PlateNumber,
		},
		repository.platformCommissionBPS,
	)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if acceptedRide.DriverID == nil || acceptedRide.CommissionBPS == nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrInvalidSettlement
	}
	dbAcceptedDriverID, err := toPostgresRideID(*acceptedRide.DriverID, "driver id")
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	createdRide, err := transactionQueries.CreateAcceptedRide(ctx, databasepostgres.CreateAcceptedRideParams{
		PassengerID:          session.PassengerID,
		DriverID:             pgtype.Int4{Int32: dbAcceptedDriverID, Valid: true},
		FareCentavos:         acceptedRide.FareCentavos,
		RideType:             acceptedRide.RideType,
		PickupLatitude:       rideFloat(acceptedRide.PickupLatitude),
		PickupLongitude:      rideFloat(acceptedRide.PickupLongitude),
		PickupName:           rideText(acceptedRide.PickupName),
		DropoffLatitude:      rideFloat(acceptedRide.DropoffLatitude),
		DropoffLongitude:     rideFloat(acceptedRide.DropoffLongitude),
		DropoffName:          rideText(acceptedRide.DropoffName),
		DistanceKm:           rideFloat(acceptedRide.DistanceKm),
		DurationMinutes:      rideFloat(acceptedRide.DurationMinutes),
		DriverName:           rideText(acceptedRide.DriverName),
		VehicleType:          rideText(acceptedRide.VehicleType),
		PlateNumber:          rideText(acceptedRide.PlateNumber),
		CommissionBps:        pgtype.Int8{Int64: *acceptedRide.CommissionBPS, Valid: true},
		CommissionCentavos:   acceptedRide.CommissionCentavos,
		DriverPayoutCentavos: acceptedRide.DriverPayoutCentavos,
	})
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("create accepted ride: %w", err)
	}
	if err := transactionQueries.CreateRideSettlement(ctx, databasepostgres.CreateRideSettlementParams{
		RideID:               createdRide.ID,
		GrossFareCentavos:    acceptedRide.FareCentavos,
		CommissionBps:        pgtype.Int8{Int64: *acceptedRide.CommissionBPS, Valid: true},
		CommissionCentavos:   acceptedRide.CommissionCentavos,
		DriverPayoutCentavos: acceptedRide.DriverPayoutCentavos,
	}); err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("create ride settlement: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("commit offer acceptance transaction: %w", err)
	}
	resultSession, err := fromPostgresBidSession(updatedSession)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	resultOffer, err := fromPostgresBidOffer(updatedOffer)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	resultRide, err := fromPostgresRide(createdRide)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	return resultSession, resultOffer, resultRide, nil
}
