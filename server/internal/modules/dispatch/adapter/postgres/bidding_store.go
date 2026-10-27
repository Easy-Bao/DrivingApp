package postgres

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (repository *Store) CreateSession(
	ctx context.Context,
	value dispatchdomain.BidSession,
) (dispatchdomain.BidSession, error) {
	if err := repository.validate(); err != nil {
		return dispatchdomain.BidSession{}, err
	}
	passengerID, err := toPostgresRideID(value.PassengerID, "passenger id")
	if err != nil {
		return dispatchdomain.BidSession{}, err
	}
	if value.ExpiresAt.IsZero() {
		return dispatchdomain.BidSession{}, errors.New("bid session expiration is required")
	}
	if value.Status == "" {
		value.Status = "open"
	}
	targetDriverID := pgtype.Int4{}
	if value.TargetDriverID != nil {
		targetID, targetErr := toPostgresRideID(*value.TargetDriverID, "target driver id")
		if targetErr != nil {
			return dispatchdomain.BidSession{}, targetErr
		}
		targetDriverID = pgtype.Int4{Int32: targetID, Valid: true}
	}
	createdAt := pgtype.Timestamptz{}
	if !value.CreatedAt.IsZero() {
		createdAt = bidTimestamp(value.CreatedAt)
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("begin bid session transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	if _, err := transactionQueries.LockUserForBidSession(ctx, passengerID); err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("lock passenger for bid session: %w", err)
	}
	now := bidTimestamp(time.Now().UTC())
	if err := transactionQueries.ExpireBidSessions(ctx, databasepostgres.ExpireBidSessionsParams{
		PassengerID: passengerID,
		ExpiresAt:   now,
	}); err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("expire previous bid sessions: %w", err)
	}
	activeSession, err := transactionQueries.HasActiveBidSession(ctx, databasepostgres.HasActiveBidSessionParams{
		PassengerID: passengerID,
		ExpiresAt:   now,
	})
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("check active bid session: %w", err)
	}
	if activeSession {
		return dispatchdomain.BidSession{}, domain.ErrActiveBooking
	}
	activeRide, err := transactionQueries.HasActivePassengerRide(ctx, passengerID)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("check active passenger ride: %w", err)
	}
	if activeRide {
		return dispatchdomain.BidSession{}, domain.ErrActiveBooking
	}

	created, err := transactionQueries.CreateBidSession(ctx, databasepostgres.CreateBidSessionParams{
		PassengerID: passengerID,

		PickupLatitude:   value.PickupLatitude,
		PickupLongitude:  value.PickupLongitude,
		PickupName:       value.PickupName,
		DropoffLatitude:  value.DropoffLatitude,
		DropoffLongitude: value.DropoffLongitude,
		DropoffName:      value.DropoffName,
		PassengerNote:    toPostgresBidText(value.PassengerNote),
		DistanceKm:       value.DistanceKm,
		DurationMinutes:  value.DurationMinutes,
		OfferedFare:      value.OfferedFareAmount,
		Status:           value.Status,
		TargetDriverID:   targetDriverID,
		ExpiresAt:        bidTimestamp(value.ExpiresAt),
		CreatedAt:        createdAt,
	})
	if err != nil {
		if isPostgresUniqueViolation(err) {
			return dispatchdomain.BidSession{}, domain.ErrActiveBooking
		}
		return dispatchdomain.BidSession{}, fmt.Errorf("create bid session: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("commit bid session transaction: %w", err)
	}
	session, err := fromPostgresBidSession(created)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("map created bid session: %w", err)
	}
	return session, nil
}

func (repository *Store) ActiveSessions(ctx context.Context, driverID *int) ([]dispatchdomain.BidSession, error) {
	if err := repository.validate(); err != nil {
		return nil, err
	}
	logger := repository.logger
	if logger == nil {
		logger = slog.Default()
	}
	timingsEnabled := ctx != nil && logger.Enabled(ctx, slog.LevelDebug)
	startTiming := func() time.Time {
		if !timingsEnabled {
			return time.Time{}
		}
		return time.Now()
	}
	measure := func(startedAt time.Time) time.Duration {
		if startedAt.IsZero() {
			return 0
		}
		return time.Since(startedAt)
	}
	totalStartedAt := startTiming()
	var (
		profileLookupDuration   time.Duration
		activeRideCountDuration time.Duration
		sessionListDuration     time.Duration
		mappingDuration         time.Duration
		sessionCount            int
		outcome                 = "failed"
	)
	defer func() {
		if !timingsEnabled {
			return
		}
		logger.LogAttrs(ctx, slog.LevelDebug, "active bid session lookup stage timings",
			slog.String("outcome", outcome),
			slog.Bool("driver_scoped", driverID != nil),
			slog.Int64("total_us", measure(totalStartedAt).Microseconds()),
			slog.Int64("online_profile_us", profileLookupDuration.Microseconds()),
			slog.Int64("active_ride_count_us", activeRideCountDuration.Microseconds()),
			slog.Int64("session_list_us", sessionListDuration.Microseconds()),
			slog.Int64("mapping_us", mappingDuration.Microseconds()),
			slog.Int("session_count", sessionCount),
		)
	}()

	now := bidTimestamp(time.Now().UTC())
	var (
		items      []databasepostgres.BidSession
		dbDriverID int32
		err        error
	)
	if driverID == nil {
		sessionListStartedAt := startTiming()
		items, err = repository.queries.ListActiveBidSessions(ctx, now)
		sessionListDuration = measure(sessionListStartedAt)
	} else {
		var idErr error
		dbDriverID, idErr = toPostgresRideID(*driverID, "driver id")
		if idErr != nil {
			return nil, idErr
		}
		profileLookupStartedAt := startTiming()
		if _, profileErr := repository.queries.GetOnlineDriverProfileForBidding(
			ctx,
			databasepostgres.GetOnlineDriverProfileForBiddingParams{
				UserID:                     dbDriverID,
				OnlineCutoff:               repository.onlinePresenceCutoff(),
				AllowUnverifiedTestDrivers: repository.allowUnverifiedTestDrivers,
			},
		); profileErr != nil {
			profileLookupDuration = measure(profileLookupStartedAt)
			outcome = "driver_unavailable"
			return nil, driverUnavailableError(
				"find online driver profile for active sessions",
				profileErr,
				dispatchdomain.ErrDriverUnavailable,
			)
		}
		profileLookupDuration = measure(profileLookupStartedAt)

		activeRideCountStartedAt := startTiming()
		activeRides, countErr := repository.queries.CountActiveRidesForDriver(
			ctx,
			pgtype.Int4{Int32: dbDriverID, Valid: true},
		)
		activeRideCountDuration = measure(activeRideCountStartedAt)
		if countErr != nil {
			return nil, fmt.Errorf("count active driver rides: %w", countErr)
		}
		if activeRides >= domain.MaxActiveRidesPerDriver {
			outcome = "active_ride_gate"
			return []dispatchdomain.BidSession{}, nil
		}

		sessionListStartedAt := startTiming()
		items, err = repository.queries.ListTargetedActiveBidSessions(
			ctx,
			databasepostgres.ListTargetedActiveBidSessionsParams{
				ExpiresAt:      now,
				TargetDriverID: pgtype.Int4{Int32: dbDriverID, Valid: true},
			},
		)
		sessionListDuration = measure(sessionListStartedAt)
	}
	if err != nil {
		return nil, fmt.Errorf("list active bid sessions: %w", err)
	}
	result := make([]dispatchdomain.BidSession, 0, len(items))
	mappingStartedAt := startTiming()
	for _, item := range items {
		session, mappingErr := fromPostgresBidSession(item)
		if mappingErr != nil {
			mappingDuration = measure(mappingStartedAt)
			outcome = "mapping_failed"
			return nil, fmt.Errorf("map active bid session: %w", mappingErr)
		}
		result = append(result, session)
	}
	mappingDuration = measure(mappingStartedAt)
	if driverID != nil && len(items) > 0 {
		sessionIDs := make([]int32, len(items))
		for index, item := range items {
			sessionIDs[index] = item.ID
		}
		pendingStartedAt := startTiming()
		pendingRows, pendingErr := repository.queries.ListPendingBidOffersForDriver(
			ctx,
			databasepostgres.ListPendingBidOffersForDriverParams{
				DriverID:   dbDriverID,
				ExpiresAt:  now,
				SessionIds: sessionIDs,
			},
		)
		if pendingErr != nil {
			return nil, fmt.Errorf("list driver's pending bid offers: %w", pendingErr)
		}
		sessionListDuration += measure(pendingStartedAt)
		pendingMappingStartedAt := startTiming()
		pendingBySession := make(map[int][]dispatchdomain.BidOffer, len(pendingRows))
		for _, row := range pendingRows {
			offer, mappingErr := fromPostgresBidOffer(row)
			if mappingErr != nil {
				return nil, fmt.Errorf("map driver's pending bid offer: %w", mappingErr)
			}
			pendingBySession[offer.SessionID] = append(
				pendingBySession[offer.SessionID],
				offer,
			)
		}
		for index := range result {
			result[index].Offers = pendingBySession[result[index].ID]
		}
		mappingDuration += measure(pendingMappingStartedAt)
	}
	sessionCount = len(result)
	outcome = "success"
	return result, nil
}

func (repository *Store) Offers(ctx context.Context, sessionID int) ([]dispatchdomain.BidOffer, error) {
	if err := repository.validate(); err != nil {
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
	sessionID, err := toPostgresRideID(value.SessionID, "session id")
	if err != nil {
		return dispatchdomain.BidOffer{}, err
	}
	driverID, err := toPostgresRideID(value.DriverID, "driver id")
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
	now := bidTimestamp(time.Now().UTC())
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
		DriverName:   toPostgresBidText(profile.Name),
		PlateNumber:  toPostgresBidText(profile.PlateNumber),
		VehicleType:  toPostgresBidText(profile.VehicleType),
		ProposedFare: value.ProposedFareAmount,
	})
	if err != nil {
		if isPostgresUniqueViolation(err) {
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

func (repository *Store) CancelSession(
	ctx context.Context,
	sessionID int,
	passengerID int,
) (dispatchdomain.BidSession, error) {
	if err := repository.validate(); err != nil {
		return dispatchdomain.BidSession{}, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return dispatchdomain.BidSession{}, err
	}
	dbPassengerID, err := toPostgresRideID(passengerID, "passenger id")
	if err != nil {
		return dispatchdomain.BidSession{}, err
	}
	if err := repository.queries.ExpireBidSessions(ctx, databasepostgres.ExpireBidSessionsParams{
		PassengerID: dbPassengerID,
		ExpiresAt:   bidTimestamp(time.Now().UTC()),
	}); err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("expire passenger bid sessions before cancellation: %w", err)
	}
	item, err := repository.queries.CancelBidSession(ctx, databasepostgres.CancelBidSessionParams{
		ID:          dbSessionID,
		PassengerID: dbPassengerID,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return dispatchdomain.BidSession{}, dispatchdomain.ErrSessionNotFound
		}
		return dispatchdomain.BidSession{}, fmt.Errorf("cancel bid session: %w", err)
	}
	session, err := fromPostgresBidSession(item)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("map canceled bid session: %w", err)
	}
	return session, nil
}

func (repository *Store) CancelOffer(ctx context.Context, sessionID, driverID int) (dispatchdomain.BidOffer, error) {
	if err := repository.validate(); err != nil {
		return dispatchdomain.BidOffer{}, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return dispatchdomain.BidOffer{}, err
	}
	dbDriverID, err := toPostgresRideID(driverID, "driver id")
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

func (repository *Store) Session(ctx context.Context, sessionID int) (dispatchdomain.BidSession, error) {
	if err := repository.validate(); err != nil {
		return dispatchdomain.BidSession{}, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return dispatchdomain.BidSession{}, err
	}
	item, err := repository.queries.GetBidSessionByID(ctx, dbSessionID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return dispatchdomain.BidSession{}, dispatchdomain.ErrSessionNotFound
		}
		return dispatchdomain.BidSession{}, fmt.Errorf("find bid session: %w", err)
	}
	session, err := fromPostgresBidSession(item)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("map bid session: %w", err)
	}
	ride, err := repository.queries.GetRideByBidSessionID(
		ctx,
		pgtype.Int4{Int32: dbSessionID, Valid: true},
	)
	if err == nil {
		rideID := int(ride.Ride.ID)
		session.RideID = &rideID
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return dispatchdomain.BidSession{}, fmt.Errorf("find ride for bid session: %w", err)
	}
	return session, nil
}

func (repository *Store) DeclineSession(ctx context.Context, sessionID, driverID int) (dispatchdomain.BidSession, error) {
	if err := repository.validate(); err != nil {
		return dispatchdomain.BidSession{}, err
	}
	dbSessionID, err := toPostgresRideID(sessionID, "session id")
	if err != nil {
		return dispatchdomain.BidSession{}, err
	}
	dbDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return dispatchdomain.BidSession{}, err
	}
	// Acceptance locks the same session row; the predicate prevents either
	// terminal transition from overwriting the other after waiting.
	item, err := repository.queries.DeclineTargetedBidSession(ctx, databasepostgres.DeclineTargetedBidSessionParams{
		ID: dbSessionID, TargetDriverID: pgtype.Int4{Int32: dbDriverID, Valid: true},
	})
	if errors.Is(err, pgx.ErrNoRows) {
		existing, readErr := repository.queries.GetBidSessionByID(ctx, dbSessionID)
		if errors.Is(readErr, pgx.ErrNoRows) {
			return dispatchdomain.BidSession{}, dispatchdomain.ErrSessionNotFound
		}
		if readErr != nil {
			return dispatchdomain.BidSession{}, fmt.Errorf("load declined ride request: %w", readErr)
		}
		if !existing.TargetDriverID.Valid || existing.TargetDriverID.Int32 != dbDriverID {
			return dispatchdomain.BidSession{}, dispatchdomain.ErrUnauthorizedSession
		}
		return dispatchdomain.BidSession{}, dispatchdomain.ErrSessionClosed
	}
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("decline targeted ride request: %w", err)
	}
	session, err := fromPostgresBidSession(item)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("map declined ride request: %w", err)
	}
	return session, nil
}
