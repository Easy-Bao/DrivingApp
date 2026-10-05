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

func (repository *RideRepository) AcceptOffer(
	ctx context.Context,
	sessionID int,
	offerID int,
	passengerID int,
) (domain.OfferAcceptance, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.OfferAcceptance{}, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return domain.OfferAcceptance{}, err
	}
	dbOfferID, err := toPostgresRideID(offerID, "offer id")
	if err != nil {
		return domain.OfferAcceptance{}, err
	}
	dbPassengerID, err := toPostgresRideID(passengerID, "passenger id")
	if err != nil {
		return domain.OfferAcceptance{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("begin offer acceptance transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	session, err := transactionQueries.LockActiveBidSessionForOffer(
		ctx,
		databasepostgres.LockActiveBidSessionForOfferParams{
			ID:        dbSessionID,
			ExpiresAt: bidTimestamp(time.Now().UTC()),
		},
	)
	if err != nil {
		existingSession, getErr := transactionQueries.GetBidSessionByID(ctx, dbSessionID)
		if getErr == nil && existingSession.Status == "accepted" && existingSession.PassengerID == dbPassengerID {
			offers, listErr := transactionQueries.ListBidOffersBySession(ctx, dbSessionID)
			if listErr == nil {
				for _, candidateOffer := range offers {
					if candidateOffer.ID == dbOfferID && candidateOffer.Status == "accepted" &&
						existingSession.AcceptedDriverID.Valid && existingSession.AcceptedDriverID.Int32 == candidateOffer.DriverID {
						activeRides, ridesErr := transactionQueries.ListActiveRidesForDriver(ctx, pgtype.Int4{
							Int32: candidateOffer.DriverID,
							Valid: true,
						})
						if ridesErr == nil {
							for _, candidateRide := range activeRides {
								if candidateRide.PassengerID == dbPassengerID {
									sessionValue, sessionErr := fromPostgresBidSession(existingSession)
									offerValue, offerErr := fromPostgresBidOffer(candidateOffer)
									rideValue, rideErr := fromPostgresRide(candidateRide)
									if sessionErr == nil && offerErr == nil && rideErr == nil {
										return domain.OfferAcceptance{
											Session: sessionValue,
											Offer:   offerValue,
											Ride:    rideValue,
										}, nil
									}
								}
							}
						}
					}
				}
			}
		}
		return domain.OfferAcceptance{}, fmt.Errorf("find active bid session: %w", err)
	}
	if session.PassengerID != dbPassengerID {
		return domain.OfferAcceptance{}, domain.ErrUnauthorizedSession
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
		return domain.OfferAcceptance{}, fmt.Errorf("find bid offer driver: %w", err)
	}
	profile, err := transactionQueries.LockOnlineDriverProfileForBidding(
		ctx,
		databasepostgres.LockOnlineDriverProfileForBiddingParams{
			UserID:       offerDriverID,
			OnlineCutoff: repository.onlinePresenceCutoff(),
		},
	)
	if err != nil {
		return domain.OfferAcceptance{}, driverUnavailableError(
			"lock online driver profile for offer acceptance",
			err,
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
		return domain.OfferAcceptance{}, fmt.Errorf("find pending bid offer: %w", err)
	}
	if session.TargetDriverID.Valid && session.TargetDriverID.Int32 != offer.DriverID {
		return domain.OfferAcceptance{}, domain.ErrUnauthorizedSession
	}
	if profile.UserID != offer.DriverID {
		return domain.OfferAcceptance{}, domain.ErrUnauthorizedSession
	}
	activeDriverRides, err := transactionQueries.CountActiveRidesForAcceptance(
		ctx,
		pgtype.Int4{Int32: profile.UserID, Valid: true},
	)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("count active driver rides: %w", err)
	}
	if activeDriverRides > 0 {
		return domain.OfferAcceptance{}, domain.ErrDriverHasActiveRide
	}
	activePassengerRide, err := transactionQueries.HasActivePassengerRide(ctx, session.PassengerID)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("check active passenger ride: %w", err)
	}
	if activePassengerRide {
		return domain.OfferAcceptance{}, domain.ErrActiveBooking
	}
	updatedOffer, err := transactionQueries.MarkBidOfferAccepted(ctx, offer.ID)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("accept bid offer: %w", err)
	}
	if err := transactionQueries.RejectOtherPendingBidOffers(ctx, databasepostgres.RejectOtherPendingBidOffersParams{
		SessionID: session.ID,
		ID:        offer.ID,
	}); err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("reject competing bid offers: %w", err)
	}
	withdrawnRows, err := transactionQueries.RejectDriverPendingBidOffers(
		ctx,
		databasepostgres.RejectDriverPendingBidOffersParams{
			DriverID: offer.DriverID,
			ID:       offer.ID,
		},
	)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("reject driver's outstanding offers: %w", err)
	}
	withdrawnOffers, err := mapBidOfferWithdrawals(ctx, transactionQueries, withdrawnRows)
	if err != nil {
		return domain.OfferAcceptance{}, err
	}
	updatedSession, err := transactionQueries.MarkBidSessionAccepted(ctx, databasepostgres.MarkBidSessionAcceptedParams{
		ID:               session.ID,
		AcceptedDriverID: pgtype.Int4{Int32: offer.DriverID, Valid: true},
	})
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("accept bid session: %w", err)
	}
	sessionValue, err := fromPostgresBidSession(session)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("map bid session for offer acceptance: %w", err)
	}
	offerValue, err := fromPostgresBidOffer(offer)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("map bid offer for offer acceptance: %w", err)
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
		return domain.OfferAcceptance{}, err
	}
	if acceptedRide.DriverID == nil || acceptedRide.CommissionBPS == nil {
		return domain.OfferAcceptance{}, domain.ErrInvalidSettlement
	}
	dbAcceptedDriverID, err := toPostgresRideID(*acceptedRide.DriverID, "driver id")
	if err != nil {
		return domain.OfferAcceptance{}, err
	}
	createdRide, err := transactionQueries.CreateAcceptedRide(ctx, databasepostgres.CreateAcceptedRideParams{
		PassengerID:        session.PassengerID,
		DriverID:           pgtype.Int4{Int32: dbAcceptedDriverID, Valid: true},
		FareAmount:         acceptedRide.FareAmount,
		RideType:           acceptedRide.RideType,
		PickupLatitude:     rideFloat(acceptedRide.PickupLatitude),
		PickupLongitude:    rideFloat(acceptedRide.PickupLongitude),
		PickupName:         rideText(acceptedRide.PickupName),
		DropoffLatitude:    rideFloat(acceptedRide.DropoffLatitude),
		DropoffLongitude:   rideFloat(acceptedRide.DropoffLongitude),
		DropoffName:        rideText(acceptedRide.DropoffName),
		DistanceKm:         rideFloat(acceptedRide.DistanceKm),
		DurationMinutes:    rideFloat(acceptedRide.DurationMinutes),
		DriverName:         rideText(acceptedRide.DriverName),
		VehicleType:        rideText(acceptedRide.VehicleType),
		PlateNumber:        rideText(acceptedRide.PlateNumber),
		CommissionBps:      pgtype.Int4{Int32: int32(*acceptedRide.CommissionBPS), Valid: true},
		CommissionAmount:   acceptedRide.CommissionAmount,
		DriverPayoutAmount: acceptedRide.DriverPayoutAmount,
	})
	if err != nil {
		return domain.OfferAcceptance{}, acceptedRideConflictError("create accepted ride", err)
	}
	if err := transactionQueries.CreateRideSettlement(ctx, databasepostgres.CreateRideSettlementParams{
		RideID:             createdRide.ID,
		GrossFare:          acceptedRide.FareAmount,
		CommissionBps:      pgtype.Int4{Int32: int32(*acceptedRide.CommissionBPS), Valid: true},
		CommissionAmount:   acceptedRide.CommissionAmount,
		DriverPayoutAmount: acceptedRide.DriverPayoutAmount,
	}); err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("create ride settlement: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("commit offer acceptance transaction: %w", err)
	}
	resultSession, err := fromPostgresBidSession(updatedSession)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("map accepted bid session: %w", err)
	}
	resultOffer, err := fromPostgresBidOffer(updatedOffer)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("map accepted bid offer: %w", err)
	}
	resultRide, err := fromPostgresRide(createdRide)
	if err != nil {
		return domain.OfferAcceptance{}, fmt.Errorf("map accepted ride: %w", err)
	}
	return domain.OfferAcceptance{
		Session:         resultSession,
		Offer:           resultOffer,
		Ride:            resultRide,
		WithdrawnOffers: withdrawnOffers,
	}, nil
}

func mapBidOfferWithdrawals(
	ctx context.Context,
	queries *databasepostgres.Queries,
	offers []databasepostgres.BidOffer,
) ([]domain.BidOfferWithdrawal, error) {
	withdrawals := make([]domain.BidOfferWithdrawal, 0, len(offers))
	for _, item := range offers {
		offer, err := fromPostgresBidOffer(item)
		if err != nil {
			return nil, fmt.Errorf("map withdrawn bid offer: %w", err)
		}
		sessionRow, err := queries.GetBidSessionByID(ctx, item.SessionID)
		if err != nil {
			return nil, fmt.Errorf("load withdrawn offer session: %w", err)
		}
		session, err := fromPostgresBidSession(sessionRow)
		if err != nil {
			return nil, fmt.Errorf("map withdrawn offer session: %w", err)
		}
		withdrawals = append(withdrawals, domain.BidOfferWithdrawal{
			Session: session,
			Offer:   offer,
		})
	}
	return withdrawals, nil
}
