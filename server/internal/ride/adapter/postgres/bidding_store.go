package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
)

var _ ports.BiddingStore = (*RideRepository)(nil)

func (repository *RideRepository) CreateSession(ctx context.Context, value domain.BidSession) (domain.BidSession, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.BidSession{}, err
	}
	passengerID, err := toPostgresRideID(value.PassengerID, "passenger id")
	if err != nil {
		return domain.BidSession{}, err
	}
	if value.ExpiresAt.IsZero() {
		return domain.BidSession{}, errors.New("bid session expiration is required")
	}
	if value.Status == "" {
		value.Status = "open"
	}
	targetDriverID := pgtype.Int4{}
	if value.TargetDriverID != nil {
		targetID, targetErr := toPostgresRideID(*value.TargetDriverID, "target driver id")
		if targetErr != nil {
			return domain.BidSession{}, targetErr
		}
		targetDriverID = pgtype.Int4{Int32: targetID, Valid: true}
	}
	createdAt := pgtype.Timestamptz{}
	if !value.CreatedAt.IsZero() {
		createdAt = bidTimestamp(value.CreatedAt)
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.BidSession{}, fmt.Errorf("begin bid session transaction: %w", err)
	}
	defer func() {
		_ = transaction.Rollback(ctx)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	if _, err := transactionQueries.LockUserForBidSession(ctx, passengerID); err != nil {
		return domain.BidSession{}, fmt.Errorf("lock passenger for bid session: %w", err)
	}
	now := bidTimestamp(time.Now().UTC())
	if err := transactionQueries.ExpireBidSessions(ctx, databasepostgres.ExpireBidSessionsParams{
		PassengerID: passengerID,
		ExpiresAt:   now,
	}); err != nil {
		return domain.BidSession{}, fmt.Errorf("expire previous bid sessions: %w", err)
	}
	activeSession, err := transactionQueries.HasActiveBidSession(ctx, databasepostgres.HasActiveBidSessionParams{
		PassengerID: passengerID,
		ExpiresAt:   now,
	})
	if err != nil {
		return domain.BidSession{}, fmt.Errorf("check active bid session: %w", err)
	}
	if activeSession {
		return domain.BidSession{}, domain.ErrActiveBooking
	}
	activeRide, err := transactionQueries.HasActivePassengerRide(ctx, passengerID)
	if err != nil {
		return domain.BidSession{}, fmt.Errorf("check active passenger ride: %w", err)
	}
	if activeRide {
		return domain.BidSession{}, domain.ErrActiveBooking
	}

	created, err := transactionQueries.CreateBidSession(ctx, databasepostgres.CreateBidSessionParams{
		PassengerID:         passengerID,
		RideType:            value.RideType,
		PickupLatitude:      value.PickupLatitude,
		PickupLongitude:     value.PickupLongitude,
		PickupName:          value.PickupName,
		DropoffLatitude:     value.DropoffLatitude,
		DropoffLongitude:    value.DropoffLongitude,
		DropoffName:         value.DropoffName,
		PassengerNote:       toPostgresBidText(value.PassengerNote),
		DistanceKm:          value.DistanceKm,
		DurationMinutes:     value.DurationMinutes,
		OfferedFareCentavos: value.OfferedFareCentavos,
		Status:              value.Status,
		TargetDriverID:      targetDriverID,
		ExpiresAt:           bidTimestamp(value.ExpiresAt),
		CreatedAt:           createdAt,
	})
	if err != nil {
		if isPostgresUniqueViolation(err) {
			return domain.BidSession{}, domain.ErrActiveBooking
		}
		return domain.BidSession{}, fmt.Errorf("create bid session: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.BidSession{}, fmt.Errorf("commit bid session transaction: %w", err)
	}
	return fromPostgresBidSession(created)
}

func (repository *RideRepository) ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	now := bidTimestamp(time.Now().UTC())
	var (
		items []databasepostgres.BidSession
		err   error
	)
	if driverID == nil {
		items, err = repository.queries.ListActiveBidSessions(ctx, now)
	} else {
		dbDriverID, idErr := toPostgresRideID(*driverID, "driver id")
		if idErr != nil {
			return nil, idErr
		}
		if _, profileErr := repository.queries.GetOnlineDriverProfileForBidding(ctx, dbDriverID); profileErr != nil {
			return nil, domain.ErrDriverUnavailable
		}
		activeRides, countErr := repository.queries.CountActiveRidesForDriver(ctx, pgtype.Int4{Int32: dbDriverID, Valid: true})
		if countErr != nil {
			return nil, fmt.Errorf("count active driver rides: %w", countErr)
		}
		if activeRides >= 5 {
			return []domain.BidSession{}, nil
		}
		items, err = repository.queries.ListTargetedActiveBidSessions(ctx, databasepostgres.ListTargetedActiveBidSessionsParams{
			ExpiresAt:      now,
			TargetDriverID: pgtype.Int4{Int32: dbDriverID, Valid: true},
		})
	}
	if err != nil {
		return nil, fmt.Errorf("list active bid sessions: %w", err)
	}
	result := make([]domain.BidSession, 0, len(items))
	for _, item := range items {
		session, mappingErr := fromPostgresBidSession(item)
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, session)
	}
	return result, nil
}

func (repository *RideRepository) Offers(ctx context.Context, sessionID int) ([]domain.BidOffer, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return nil, err
	}
	items, err := repository.queries.ListBidOffersBySession(ctx, dbSessionID)
	if err != nil {
		return nil, fmt.Errorf("list bid offers: %w", err)
	}
	result := make([]domain.BidOffer, 0, len(items))
	for _, item := range items {
		offer, mappingErr := fromPostgresBidOffer(item)
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, offer)
	}
	return result, nil
}

func (repository *RideRepository) PlaceOffer(ctx context.Context, value domain.BidOffer) (domain.BidOffer, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.BidOffer{}, err
	}
	if value.ProposedFareCentavos <= 0 {
		return domain.BidOffer{}, domain.ErrInvalidFareOffer
	}
	sessionID, err := toPostgresRideID(value.SessionID, "session id")
	if err != nil {
		return domain.BidOffer{}, err
	}
	driverID, err := toPostgresRideID(value.DriverID, "driver id")
	if err != nil {
		return domain.BidOffer{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.BidOffer{}, fmt.Errorf("begin bid offer transaction: %w", err)
	}
	defer func() {
		_ = transaction.Rollback(ctx)
	}()
	transactionQueries := repository.queries.WithTx(transaction)
	now := bidTimestamp(time.Now().UTC())
	session, err := transactionQueries.LockActiveBidSessionForOffer(ctx, databasepostgres.LockActiveBidSessionForOfferParams{
		ID:        sessionID,
		ExpiresAt: now,
	})
	if err != nil {
		return domain.BidOffer{}, domain.ErrDriverUnavailable
	}
	if session.TargetDriverID.Valid && session.TargetDriverID.Int32 != driverID {
		return domain.BidOffer{}, domain.ErrDriverUnavailable
	}
	profile, err := transactionQueries.LockOnlineDriverProfileForBidding(ctx, driverID)
	if err != nil {
		return domain.BidOffer{}, domain.ErrDriverUnavailable
	}
	activeRides, err := transactionQueries.CountActiveRidesForDriver(ctx, pgtype.Int4{Int32: profile.UserID, Valid: true})
	if err != nil {
		return domain.BidOffer{}, fmt.Errorf("count active driver rides: %w", err)
	}
	if activeRides >= 5 {
		return domain.BidOffer{}, domain.ErrDriverAtCapacity
	}
	existing, err := transactionQueries.HasPendingBidOffer(ctx, databasepostgres.HasPendingBidOfferParams{
		SessionID: sessionID,
		DriverID:  driverID,
	})
	if err != nil {
		return domain.BidOffer{}, fmt.Errorf("check duplicate bid offer: %w", err)
	}
	if existing {
		return domain.BidOffer{}, domain.ErrDuplicateBid
	}
	created, err := transactionQueries.CreateBidOffer(ctx, databasepostgres.CreateBidOfferParams{
		SessionID:            sessionID,
		DriverID:             driverID,
		DriverName:           toPostgresBidText(profile.Name),
		PlateNumber:          toPostgresBidText(profile.PlateNumber),
		VehicleType:          toPostgresBidText(profile.VehicleType),
		ProposedFareCentavos: value.ProposedFareCentavos,
	})
	if err != nil {
		if isPostgresUniqueViolation(err) {
			return domain.BidOffer{}, domain.ErrDuplicateBid
		}
		return domain.BidOffer{}, fmt.Errorf("create bid offer: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.BidOffer{}, fmt.Errorf("commit bid offer transaction: %w", err)
	}
	return fromPostgresBidOffer(created)
}

func (repository *RideRepository) CancelSession(ctx context.Context, sessionID, passengerID int) (domain.BidSession, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.BidSession{}, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return domain.BidSession{}, err
	}
	dbPassengerID, err := toPostgresRideID(passengerID, "passenger id")
	if err != nil {
		return domain.BidSession{}, err
	}
	item, err := repository.queries.CancelBidSession(ctx, databasepostgres.CancelBidSessionParams{
		ID:          dbSessionID,
		PassengerID: dbPassengerID,
	})
	if err != nil {
		return domain.BidSession{}, fmt.Errorf("cancel bid session: %w", err)
	}
	return fromPostgresBidSession(item)
}

func (repository *RideRepository) CancelOffer(ctx context.Context, sessionID, driverID int) (domain.BidOffer, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.BidOffer{}, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return domain.BidOffer{}, err
	}
	dbDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return domain.BidOffer{}, err
	}
	pending, err := repository.queries.GetPendingBidOffer(ctx, databasepostgres.GetPendingBidOfferParams{
		SessionID: dbSessionID,
		DriverID:  dbDriverID,
	})
	if err != nil {
		return domain.BidOffer{}, fmt.Errorf("find pending bid offer: %w", err)
	}
	item, err := repository.queries.RejectBidOffer(ctx, pending.ID)
	if err != nil {
		return domain.BidOffer{}, fmt.Errorf("reject bid offer: %w", err)
	}
	return fromPostgresBidOffer(item)
}

func (repository *RideRepository) Session(ctx context.Context, sessionID int) (domain.BidSession, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.BidSession{}, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return domain.BidSession{}, err
	}
	item, err := repository.queries.GetBidSessionByID(ctx, dbSessionID)
	if err != nil {
		return domain.BidSession{}, fmt.Errorf("find bid session: %w", err)
	}
	return fromPostgresBidSession(item)
}

func fromPostgresBidSession(item databasepostgres.BidSession) (domain.BidSession, error) {
	if !item.ExpiresAt.Valid {
		return domain.BidSession{}, errors.New("bid session expiration time is null")
	}
	if !item.CreatedAt.Valid {
		return domain.BidSession{}, errors.New("bid session creation time is null")
	}
	var targetDriverID, acceptedDriverID *int
	if item.TargetDriverID.Valid && item.TargetDriverID.Int32 > 0 {
		value := int(item.TargetDriverID.Int32)
		targetDriverID = &value
	}
	if item.AcceptedDriverID.Valid && item.AcceptedDriverID.Int32 > 0 {
		value := int(item.AcceptedDriverID.Int32)
		acceptedDriverID = &value
	}
	return domain.BidSession{
		ID:                  int(item.ID),
		PassengerID:         int(item.PassengerID),
		RideType:            item.RideType,
		PickupLatitude:      item.PickupLatitude,
		PickupLongitude:     item.PickupLongitude,
		PickupName:          item.PickupName,
		DropoffLatitude:     item.DropoffLatitude,
		DropoffLongitude:    item.DropoffLongitude,
		DropoffName:         item.DropoffName,
		PassengerNote:       bidTextValue(item.PassengerNote),
		DistanceKm:          item.DistanceKm,
		DurationMinutes:     item.DurationMinutes,
		OfferedFareCentavos: item.OfferedFareCentavos,
		Status:              item.Status,
		TargetDriverID:      targetDriverID,
		AcceptedDriverID:    acceptedDriverID,
		ExpiresAt:           item.ExpiresAt.Time,
		CreatedAt:           item.CreatedAt.Time,
	}, nil
}

func fromPostgresBidOffer(item databasepostgres.BidOffer) (domain.BidOffer, error) {
	if !item.CreatedAt.Valid {
		return domain.BidOffer{}, errors.New("bid offer creation time is null")
	}
	return domain.BidOffer{
		ID:                   int64(item.ID),
		SessionID:            int(item.SessionID),
		DriverID:             int(item.DriverID),
		DriverName:           bidTextValue(item.DriverName),
		PlateNumber:          bidTextValue(item.PlateNumber),
		VehicleType:          bidTextValue(item.VehicleType),
		ProposedFareCentavos: item.ProposedFareCentavos,
		Status:               item.Status,
		CreatedAt:            item.CreatedAt.Time,
	}, nil
}

func bidTimestamp(value time.Time) pgtype.Timestamptz {
	return pgtype.Timestamptz{Time: value, Valid: true}
}

func toPostgresBidText(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}

func bidTextValue(value pgtype.Text) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

func isPostgresUniqueViolation(err error) bool {
	var databaseError *pgconn.PgError
	return errors.As(err, &databaseError) && databaseError.Code == "23505"
}
