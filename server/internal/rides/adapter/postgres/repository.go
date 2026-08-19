package postgres

import (
	"context"
	"database/sql"
	"strings"
	"time"

	entsql "entgo.io/ent/dialect/sql"
	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/bid"
	"github.com/Easy-Bao/DrivingApp/server/ent/bidoffer"
	"github.com/Easy-Bao/DrivingApp/server/ent/bidsession"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/passengerprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/passengerreview"
	"github.com/Easy-Bao/DrivingApp/server/ent/review"
	"github.com/Easy-Bao/DrivingApp/server/ent/ride"
	"github.com/Easy-Bao/DrivingApp/server/ent/user"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type Repository struct {
	client                *ent.Client
	platformCommissionBPS int64
}

func NewRepository(client *ent.Client, platformCommissionBPS int64) *Repository {
	return &Repository{client: client, platformCommissionBPS: platformCommissionBPS}
}
func (repository *Repository) CreateRide(ctx context.Context, value domain.Ride) (domain.Ride, error) {
	builder := repository.client.Ride.Create().SetPassengerID(value.PassengerID).SetStatus(value.Status).SetFareCentavos(value.FareCentavos).SetRideType(value.RideType)
	builder.SetPickupLatitude(value.PickupLatitude).SetPickupLongitude(value.PickupLongitude).SetPickupName(value.PickupName)
	builder.SetDropoffLatitude(value.DropoffLatitude).SetDropoffLongitude(value.DropoffLongitude).SetDropoffName(value.DropoffName)
	builder.SetDistanceKm(value.DistanceKm).SetDurationMinutes(value.DurationMinutes)
	item, err := builder.Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	return fromRide(item), nil
}
func (repository *Repository) CreateBid(ctx context.Context, value domain.Bid) (domain.Bid, error) {
	transaction, err := repository.client.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return domain.Bid{}, err
	}
	defer transaction.Rollback()
	if _, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(value.DriverID), driverprofile.IsOnlineEQ(true)).Only(ctx); err != nil {
		return domain.Bid{}, domain.ErrDriverUnavailable
	}
	if _, err := transaction.Ride.Query().Where(ride.IDEQ(value.RideID), ride.StatusEQ("requested")).Only(ctx); err != nil {
		return domain.Bid{}, domain.ErrDriverUnavailable
	}
	exists, err := transaction.Bid.Query().Where(bid.RideIDEQ(value.RideID), bid.DriverIDEQ(value.DriverID), bid.StatusEQ("pending")).Exist(ctx)
	if err != nil {
		return domain.Bid{}, err
	}
	if exists {
		return domain.Bid{}, domain.ErrDuplicateBid
	}
	item, err := transaction.Bid.Create().SetRideID(value.RideID).SetDriverID(value.DriverID).SetOfferedFareCentavos(value.FareCentavos).SetStatus(value.Status).Save(ctx)
	if err != nil {
		return domain.Bid{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.Bid{}, err
	}
	return fromBid(item), nil
}
func (repository *Repository) Get(ctx context.Context, id int) (domain.Ride, error) {
	item, err := repository.client.Ride.Get(ctx, id)
	if err != nil {
		return domain.Ride{}, err
	}
	rides, err := repository.hydrateDriverDetails(ctx, []domain.Ride{fromRide(item)})
	if err != nil {
		return domain.Ride{}, err
	}
	return rides[0], nil
}
func (repository *Repository) AcceptBid(ctx context.Context, bidID, driverID int) (domain.Bid, domain.Ride, error) {
	transaction, err := repository.client.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	offer, err := transaction.Bid.Query().Where(bid.IDEQ(bidID), bid.DriverIDEQ(driverID), bid.StatusEQ("pending")).Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(driverID), driverprofile.IsOnlineEQ(true)).Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, domain.ErrDriverUnavailable
	}
	active, err := transaction.Ride.Query().Where(ride.DriverIDEQ(profile.UserID), ride.StatusIn("accepted", "arrived", "in_transit")).Count(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	if active >= 5 {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, domain.ErrDriverAtCapacity
	}
	updated, err := offer.Update().SetStatus("accepted").Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	trip, err := transaction.Ride.Query().Where(ride.IDEQ(offer.RideID), ride.StatusEQ("requested")).Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	trip, err = trip.Update().
		SetStatus("assigned").
		SetDriverID(driverID).
		SetDriverName(profile.Name).
		SetVehicleType(profile.VehicleType).
		SetPlateNumber(profile.PlateNumber).
		Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	return fromBid(updated), fromRide(trip), nil
}

func (repository *Repository) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	transaction, err := repository.client.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return domain.Ride{}, err
	}
	defer transaction.Rollback()
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(driverID), driverprofile.IsOnlineEQ(true)).Only(ctx)
	if err != nil {
		return domain.Ride{}, domain.ErrDriverUnavailable
	}
	item, err := transaction.Ride.Query().Where(ride.IDEQ(rideID), ride.StatusEQ("requested")).Only(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	active, err := transaction.Ride.Query().Where(ride.DriverIDEQ(driverID), ride.StatusIn("accepted", "arrived", "in_transit")).Count(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if active >= 5 {
		return domain.Ride{}, domain.ErrDriverAtCapacity
	}
	updated, err := item.Update().
		SetDriverID(driverID).
		SetStatus("accepted").
		SetDriverName(profile.Name).
		SetVehicleType(profile.VehicleType).
		SetPlateNumber(profile.PlateNumber).
		Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.Ride{}, err
	}
	return fromRide(updated), nil
}

func (repository *Repository) SettleCash(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	transaction, err := repository.client.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return domain.Ride{}, err
	}
	defer transaction.Rollback()
	rideItem, err := transaction.Ride.Query().Where(ride.IDEQ(rideID), ride.DriverIDEQ(driverID), ride.StatusEQ("completed")).Only(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if rideItem.PaymentStatus == "paid" {
		return fromRide(rideItem), nil
	}
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(driverID)).Only(ctx)
	if err != nil {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	commission := rideItem.FareCentavos * repository.platformCommissionBPS / 10000
	payout := rideItem.FareCentavos - commission
	if payout <= 0 {
		return domain.Ride{}, domain.ErrInvalidFareOffer
	}
	_, err = transaction.WalletLedger.Create().SetDriverID(driverID).SetRideID(rideID).SetAmountCentavos(payout).SetCommissionCentavos(commission).SetKind("cash_trip").Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if _, err = profile.Update().AddWalletBalanceCentavos(payout).Save(ctx); err != nil {
		return domain.Ride{}, err
	}
	updatedRide, err := rideItem.Update().SetPaymentStatus("paid").SetCashReceivedAt(time.Now()).SetCommissionCentavos(commission).SetDriverPayoutCentavos(payout).Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.Ride{}, err
	}
	return fromRide(updatedRide), nil
}

func (repository *Repository) UpdateStatus(ctx context.Context, rideID, actorID int, currentStatus, status string) (domain.Ride, error) {
	update := repository.client.Ride.UpdateOneID(rideID).Where(ride.StatusEQ(currentStatus), ride.Or(ride.PassengerIDEQ(actorID), ride.DriverIDEQ(actorID))).SetStatus(status)
	if status == "completed" || status == "canceled" || status == "cancelled" {
		update.SetCompletedAt(time.Now())
	}
	item, err := update.Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	return fromRide(item), nil
}

func (repository *Repository) CreateSession(ctx context.Context, value domain.BidSession) (domain.BidSession, error) {
	transaction, err := repository.client.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return domain.BidSession{}, err
	}
	defer transaction.Rollback()
	activeSession, err := transaction.BidSession.Query().Where(bidsession.PassengerIDEQ(value.PassengerID), bidsession.StatusEQ("open"), bidsession.ExpiresAtGT(time.Now())).Exist(ctx)
	if err != nil {
		return domain.BidSession{}, err
	}
	if activeSession {
		return domain.BidSession{}, domain.ErrActiveBooking
	}
	activeRide, err := transaction.Ride.Query().Where(ride.PassengerIDEQ(value.PassengerID), ride.StatusIn("requested", "assigned", "accepted", "arrived", "in_transit")).Exist(ctx)
	if err != nil {
		return domain.BidSession{}, err
	}
	if activeRide {
		return domain.BidSession{}, domain.ErrActiveBooking
	}
	builder := transaction.BidSession.Create().
		SetPassengerID(value.PassengerID).
		SetRideType(value.RideType).
		SetPickupLatitude(value.PickupLatitude).
		SetPickupLongitude(value.PickupLongitude).
		SetPickupName(value.PickupName).
		SetDropoffLatitude(value.DropoffLatitude).
		SetDropoffLongitude(value.DropoffLongitude).
		SetDropoffName(value.DropoffName).
		SetDistanceKm(value.DistanceKm).
		SetDurationMinutes(value.DurationMinutes).
		SetOfferedFareCentavos(value.OfferedFareCentavos).
		SetStatus(value.Status).
		SetExpiresAt(value.ExpiresAt)
	if value.TargetDriverID != nil {
		builder.SetTargetDriverID(*value.TargetDriverID)
	}
	if !value.CreatedAt.IsZero() {
		builder.SetCreatedAt(value.CreatedAt)
	}
	item, err := builder.Save(ctx)
	if err != nil {
		return domain.BidSession{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.BidSession{}, err
	}
	return fromSession(item), nil
}

func (repository *Repository) ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error) {
	query := repository.client.BidSession.Query().Where(bidsession.StatusEQ("open"), bidsession.ExpiresAtGT(time.Now()))
	pendingSessionIDs := map[int]struct{}{}
	if driverID != nil {
		profile, err := repository.client.DriverProfile.Query().Where(driverprofile.UserIDEQ(*driverID), driverprofile.IsOnlineEQ(true)).Only(ctx)
		if err != nil {
			return nil, domain.ErrDriverUnavailable
		}
		active, err := repository.client.Ride.Query().Where(ride.DriverIDEQ(profile.UserID), ride.StatusIn("accepted", "arrived", "in_transit")).Count(ctx)
		if err != nil {
			return nil, err
		}
		if active >= 5 {
			return []domain.BidSession{}, nil
		}
		query.Where(bidsession.Or(bidsession.TargetDriverID(0), bidsession.TargetDriverIDEQ(*driverID)))
		pendingOffers, err := repository.client.BidOffer.Query().Where(
			bidoffer.DriverIDEQ(*driverID),
			bidoffer.StatusEQ("pending"),
		).All(ctx)
		if err != nil {
			return nil, err
		}
		for _, offer := range pendingOffers {
			pendingSessionIDs[offer.SessionID] = struct{}{}
		}
	}
	items, err := query.Order(bidsession.ByCreatedAt()).Limit(50).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.BidSession, 0, len(items))
	for _, item := range items {
		if _, hasPendingOffer := pendingSessionIDs[item.ID]; hasPendingOffer {
			continue
		}
		result = append(result, fromSession(item))
	}
	return result, nil
}

func (repository *Repository) Offers(ctx context.Context, sessionID int) ([]domain.BidOffer, error) {
	items, err := repository.client.BidOffer.Query().Where(bidoffer.SessionIDEQ(sessionID)).Order(bidoffer.ByCreatedAt()).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.BidOffer, 0, len(items))
	for _, item := range items {
		result = append(result, fromOffer(item))
	}
	return result, nil
}

func (repository *Repository) PlaceOffer(ctx context.Context, value domain.BidOffer) (domain.BidOffer, error) {
	session, err := repository.client.BidSession.Get(ctx, value.SessionID)
	if err != nil || session.Status != "open" || !session.ExpiresAt.After(time.Now()) {
		return domain.BidOffer{}, domain.ErrDriverUnavailable
	}
	if session.TargetDriverID != 0 && session.TargetDriverID != value.DriverID {
		return domain.BidOffer{}, domain.ErrDriverUnavailable
	}
	profile, err := repository.client.DriverProfile.Query().Where(driverprofile.UserIDEQ(value.DriverID), driverprofile.IsOnlineEQ(true)).Only(ctx)
	if err != nil {
		return domain.BidOffer{}, domain.ErrDriverUnavailable
	}
	active, err := repository.client.Ride.Query().Where(ride.DriverIDEQ(profile.UserID), ride.StatusIn("accepted", "arrived", "in_transit")).Count(ctx)
	if err != nil {
		return domain.BidOffer{}, err
	}
	if active >= 5 {
		return domain.BidOffer{}, domain.ErrDriverAtCapacity
	}
	existing, err := repository.client.BidOffer.Query().Where(bidoffer.SessionIDEQ(value.SessionID), bidoffer.DriverIDEQ(value.DriverID), bidoffer.StatusEQ("pending")).Exist(ctx)
	if err != nil {
		return domain.BidOffer{}, err
	}
	if existing {
		return domain.BidOffer{}, context.Canceled
	}
	builder := repository.client.BidOffer.Create().SetSessionID(value.SessionID).SetDriverID(value.DriverID).SetDriverName(profile.Name).SetPlateNumber(profile.PlateNumber).SetVehicleType(profile.VehicleType).SetProposedFareCentavos(value.ProposedFareCentavos).SetStatus("pending")
	item, err := builder.Save(ctx)
	if err != nil {
		return domain.BidOffer{}, err
	}
	return fromOffer(item), nil
}

func (repository *Repository) AcceptOffer(ctx context.Context, sessionID, offerID, passengerID int) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	transaction, err := repository.client.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	session, err := transaction.BidSession.Query().Where(bidsession.IDEQ(sessionID), bidsession.StatusEQ("open"), bidsession.ExpiresAtGT(time.Now())).Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if session.PassengerID != passengerID {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	offerQuery := transaction.BidOffer.Query().Where(bidoffer.IDEQ(offerID), bidoffer.SessionIDEQ(sessionID), bidoffer.StatusEQ("pending"))
	offer, err := offerQuery.Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if session.TargetDriverID != 0 && session.TargetDriverID != offer.DriverID {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(offer.DriverID), driverprofile.IsOnlineEQ(true)).Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrDriverUnavailable
	}
	activeDriverRides, err := transaction.Ride.Query().Where(ride.DriverIDEQ(profile.UserID), ride.StatusIn("accepted", "arrived", "in_transit")).Count(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if activeDriverRides >= 5 {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrDriverAtCapacity
	}
	activePassengerRide, err := transaction.Ride.Query().Where(ride.PassengerIDEQ(session.PassengerID), ride.StatusIn("requested", "assigned", "accepted", "arrived", "in_transit")).Exist(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if activePassengerRide {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrActiveBooking
	}
	updatedOffer, err := offer.Update().SetStatus("accepted").Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	_, err = transaction.BidOffer.Update().Where(bidoffer.SessionIDEQ(sessionID), bidoffer.StatusEQ("pending"), bidoffer.IDNEQ(offerID)).SetStatus("rejected").Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	updatedSession, err := session.Update().SetStatus("accepted").SetAcceptedDriverID(offer.DriverID).Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	rideItem, err := transaction.Ride.Create().SetPassengerID(session.PassengerID).SetDriverID(offer.DriverID).SetStatus("accepted").SetFareCentavos(session.OfferedFareCentavos).SetRideType(session.RideType).SetPickupLatitude(session.PickupLatitude).SetPickupLongitude(session.PickupLongitude).SetPickupName(session.PickupName).SetDropoffLatitude(session.DropoffLatitude).SetDropoffLongitude(session.DropoffLongitude).SetDropoffName(session.DropoffName).SetDistanceKm(session.DistanceKm).SetDurationMinutes(session.DurationMinutes).SetDriverName(profile.Name).SetVehicleType(profile.VehicleType).SetPlateNumber(profile.PlateNumber).Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	return fromSession(updatedSession), fromOffer(updatedOffer), fromRide(rideItem), nil
}

func (repository *Repository) CancelSession(ctx context.Context, sessionID, passengerID int) (domain.BidSession, error) {
	item, err := repository.client.BidSession.UpdateOneID(sessionID).Where(bidsession.PassengerIDEQ(passengerID), bidsession.StatusEQ("open")).SetStatus("canceled").Save(ctx)
	if err != nil {
		return domain.BidSession{}, err
	}
	return fromSession(item), nil
}

func (repository *Repository) CancelOffer(ctx context.Context, sessionID, driverID int) (domain.BidOffer, error) {
	pending, err := repository.client.BidOffer.Query().Where(bidoffer.SessionIDEQ(sessionID), bidoffer.DriverIDEQ(driverID), bidoffer.StatusEQ("pending")).Only(ctx)
	if err != nil {
		return domain.BidOffer{}, err
	}
	item, err := pending.Update().SetStatus("rejected").Save(ctx)
	if err != nil {
		return domain.BidOffer{}, err
	}
	return fromOffer(item), nil
}

func (repository *Repository) Session(ctx context.Context, sessionID int) (domain.BidSession, error) {
	item, err := repository.client.BidSession.Get(ctx, sessionID)
	if err != nil {
		return domain.BidSession{}, err
	}
	return fromSession(item), nil
}

func (repository *Repository) DriverStats(ctx context.Context, driverID int) (domain.DriverStats, error) {
	rides, err := repository.client.Ride.Query().Where(ride.DriverIDEQ(driverID)).All(ctx)
	if err != nil {
		return domain.DriverStats{}, err
	}
	stats := domain.DriverStats{DriverID: driverID}
	for _, item := range rides {
		stats.TotalTrips++
		if item.Status == "completed" {
			stats.CompletedTrips++
			stats.TotalFare += item.FareCentavos
		}
		if item.Status != "completed" && item.Status != "cancelled" && item.Status != "canceled" {
			stats.ActiveTrips++
		}
	}
	items, err := repository.client.Review.Query().Where(review.DriverIDEQ(driverID)).All(ctx)
	if err != nil {
		return domain.DriverStats{}, err
	}
	for _, item := range items {
		stats.AverageRating += item.Rating
	}
	if len(items) > 0 {
		stats.AverageRating /= float64(len(items))
	}
	return stats, nil
}

func (repository *Repository) DriverTrips(ctx context.Context, driverID int) ([]domain.Ride, error) {
	items, err := repository.client.Ride.Query().Where(ride.DriverIDEQ(driverID)).Order(ride.ByID()).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Ride, 0, len(items))
	for index := len(items) - 1; index >= 0; index-- {
		result = append(result, fromRide(items[index]))
	}
	hydrated, err := repository.hydrateDriverDetails(ctx, result)
	if err != nil {
		return nil, err
	}
	return repository.hydratePassengerDetails(ctx, hydrated)
}

func (repository *Repository) PassengerRides(ctx context.Context, passengerID int) ([]domain.Ride, error) {
	items, err := repository.client.Ride.Query().Where(ride.PassengerIDEQ(passengerID)).Order(ride.ByID()).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Ride, 0, len(items))
	for index := len(items) - 1; index >= 0; index-- {
		result = append(result, fromRide(items[index]))
	}
	return repository.hydrateDriverDetails(ctx, result)
}

func (repository *Repository) PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]domain.Ride, error) {
	items, err := repository.client.Ride.Query().
		Where(ride.PassengerIDEQ(passengerID)).
		Order(ride.ByID(entsql.OrderDesc())).
		Limit(limit).
		All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Ride, 0, len(items))
	for _, item := range items {
		result = append(result, fromRide(item))
	}
	return repository.hydrateDriverDetails(ctx, result)
}

func (repository *Repository) hydrateDriverDetails(ctx context.Context, rides []domain.Ride) ([]domain.Ride, error) {
	driverIDs := make([]int, 0)
	seen := make(map[int]struct{})
	for _, item := range rides {
		if item.DriverID == nil {
			continue
		}
		if _, exists := seen[*item.DriverID]; exists {
			continue
		}
		seen[*item.DriverID] = struct{}{}
		driverIDs = append(driverIDs, *item.DriverID)
	}
	if len(driverIDs) == 0 {
		return rides, nil
	}

	profiles, err := repository.client.DriverProfile.Query().
		Where(driverprofile.UserIDIn(driverIDs...)).
		All(ctx)
	if err != nil {
		return nil, err
	}
	profilesByUserID := make(map[int]*ent.DriverProfile, len(profiles))
	for _, profile := range profiles {
		profilesByUserID[profile.UserID] = profile
	}

	for index := range rides {
		driverID := rides[index].DriverID
		if driverID == nil {
			continue
		}
		profile := profilesByUserID[*driverID]
		if profile == nil {
			continue
		}
		if rides[index].DriverName == "" {
			rides[index].DriverName = profile.Name
		}
		if rides[index].VehicleType == "" {
			rides[index].VehicleType = profile.VehicleType
		}
		if rides[index].PlateNumber == "" {
			rides[index].PlateNumber = profile.PlateNumber
		}
	}
	return rides, nil
}

func (repository *Repository) hydratePassengerDetails(ctx context.Context, rides []domain.Ride) ([]domain.Ride, error) {
	passengerIDs := make([]int, 0)
	seen := make(map[int]struct{})
	for _, item := range rides {
		if item.PassengerID <= 0 {
			continue
		}
		if _, exists := seen[item.PassengerID]; exists {
			continue
		}
		seen[item.PassengerID] = struct{}{}
		passengerIDs = append(passengerIDs, item.PassengerID)
	}
	if len(passengerIDs) == 0 {
		return rides, nil
	}

	users, err := repository.client.User.Query().Where(user.IDIn(passengerIDs...)).All(ctx)
	if err != nil {
		return nil, err
	}
	usersByID := make(map[int]*ent.User, len(users))
	for _, account := range users {
		usersByID[account.ID] = account
	}

	profiles, err := repository.client.PassengerProfile.Query().Where(
		passengerprofile.UserIDIn(passengerIDs...),
	).All(ctx)
	if err != nil {
		return nil, err
	}
	profilesByUserID := make(map[int]*ent.PassengerProfile, len(profiles))
	for _, profile := range profiles {
		profilesByUserID[profile.UserID] = profile
	}

	reviews, err := repository.client.PassengerReview.Query().Where(
		passengerreview.PassengerIDIn(passengerIDs...),
	).Order(passengerreview.ByCreatedAt(entsql.OrderDesc())).All(ctx)
	if err != nil {
		return nil, err
	}
	type reviewSummary struct {
		totalRating float64
		count       int
		feedback    string
	}
	reviewSummaries := make(map[int]reviewSummary, len(passengerIDs))
	for _, item := range reviews {
		summary := reviewSummaries[item.PassengerID]
		summary.totalRating += item.Rating
		summary.count++
		if summary.feedback == "" {
			summary.feedback = strings.TrimSpace(item.Comment)
		}
		reviewSummaries[item.PassengerID] = summary
	}

	for index := range rides {
		passengerID := rides[index].PassengerID
		account := usersByID[passengerID]
		profile := profilesByUserID[passengerID]
		if profile != nil {
			rides[index].PassengerName = profile.Name
		}
		if rides[index].PassengerName == "" && account != nil {
			rides[index].PassengerName = account.Name
		}
		if account != nil {
			rides[index].PassengerPhone = account.Phone
		}
		if summary, exists := reviewSummaries[passengerID]; exists && summary.count > 0 {
			rides[index].PassengerRating = summary.totalRating / float64(summary.count)
			rides[index].PassengerFeedback = summary.feedback
		}
	}
	return rides, nil
}

func (repository *Repository) DriverReviews(ctx context.Context, driverID, limit, offset int) ([]domain.Review, error) {
	query := repository.client.Review.Query().Where(review.DriverIDEQ(driverID)).Order(review.ByID())
	if limit > 0 {
		query = query.Limit(limit)
	}
	if offset > 0 {
		query = query.Offset(offset)
	}
	items, err := query.All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Review, 0, len(items))
	for index := len(items) - 1; index >= 0; index-- {
		result = append(result, fromReview(items[index]))
	}
	return result, nil
}

func (repository *Repository) CreateReview(ctx context.Context, value domain.Review) (domain.Review, error) {
	trip, err := repository.client.Ride.Get(ctx, value.RideID)
	if err != nil || trip.Status != "completed" || trip.PassengerID != value.PassengerID || trip.DriverID != value.DriverID {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}
	if exists, err := repository.client.Review.Query().Where(review.RideIDEQ(value.RideID)).Exist(ctx); err != nil {
		return domain.Review{}, err
	} else if exists {
		return domain.Review{}, domain.ErrReviewAlreadySubmitted
	}
	item, err := repository.client.Review.Create().SetRideID(value.RideID).SetDriverID(value.DriverID).SetPassengerID(value.PassengerID).SetPassengerName(value.PassengerName).SetRating(value.Rating).SetComment(value.Comment).Save(ctx)
	if err != nil {
		return domain.Review{}, err
	}
	return fromReview(item), nil
}

func (repository *Repository) CreatePassengerReview(ctx context.Context, value domain.PassengerReview) (domain.PassengerReview, error) {
	trip, err := repository.client.Ride.Get(ctx, value.RideID)
	if err != nil || trip.Status != "completed" || trip.PassengerID != value.PassengerID || trip.DriverID != value.DriverID {
		return domain.PassengerReview{}, domain.ErrReviewNotAllowed
	}
	if exists, err := repository.client.PassengerReview.Query().Where(passengerreview.RideIDEQ(value.RideID)).Exist(ctx); err != nil {
		return domain.PassengerReview{}, err
	} else if exists {
		return domain.PassengerReview{}, domain.ErrReviewAlreadySubmitted
	}
	item, err := repository.client.PassengerReview.Create().SetRideID(value.RideID).SetDriverID(value.DriverID).SetPassengerID(value.PassengerID).SetRating(value.Rating).SetComment(value.Comment).Save(ctx)
	if err != nil {
		return domain.PassengerReview{}, err
	}
	return fromPassengerReview(item), nil
}

func (repository *Repository) OnlineDrivers(ctx context.Context) ([]domain.OnlineDriver, error) {
	items, err := repository.client.DriverProfile.Query().Where(driverprofile.IsOnlineEQ(true)).Order(driverprofile.ByID()).All(ctx)
	if err != nil {
		return nil, err
	}
	driverIDs := make([]int, 0, len(items))
	for _, item := range items {
		driverIDs = append(driverIDs, item.UserID)
	}

	activePassengerCounts := make(map[int]int, len(driverIDs))
	if len(driverIDs) > 0 {
		activeRides, err := repository.client.Ride.Query().Where(
			ride.DriverIDIn(driverIDs...),
			ride.StatusIn("accepted", "arrived", "in_transit"),
		).All(ctx)
		if err != nil {
			return nil, err
		}
		for _, activeRide := range activeRides {
			activePassengerCounts[activeRide.DriverID]++
		}
	}

	type reviewSummary struct {
		totalRating float64
		count       int
		feedback    string
	}
	reviewSummaries := make(map[int]reviewSummary, len(driverIDs))
	if len(driverIDs) > 0 {
		reviews, err := repository.client.Review.Query().Where(
			review.DriverIDIn(driverIDs...),
		).Order(review.ByID(entsql.OrderDesc())).All(ctx)
		if err != nil {
			return nil, err
		}
		for _, item := range reviews {
			summary := reviewSummaries[item.DriverID]
			summary.totalRating += item.Rating
			summary.count++
			if summary.feedback == "" {
				summary.feedback = strings.TrimSpace(item.Comment)
			}
			reviewSummaries[item.DriverID] = summary
		}
	}

	result := make([]domain.OnlineDriver, 0, len(items))
	for _, item := range items {
		summary := reviewSummaries[item.UserID]
		rating := item.Rating
		if summary.count > 0 {
			rating = summary.totalRating / float64(summary.count)
		}
		result = append(result, domain.OnlineDriver{
			ID:                    item.UserID,
			UserID:                item.UserID,
			Name:                  item.Name,
			VehicleType:           item.VehicleType,
			PlateNumber:           item.PlateNumber,
			Rating:                rating,
			OnboardPassengerCount: activePassengerCounts[item.UserID],
			RecentFeedback:        summary.feedback,
		})
	}
	return result, nil
}
func fromRide(item *ent.Ride) domain.Ride {
	var driverID *int
	if item.DriverID != 0 {
		driverID = &item.DriverID
	}
	var completedAt *string
	if !item.CompletedAt.IsZero() {
		value := item.CompletedAt.UTC().Format(time.RFC3339)
		completedAt = &value
	}
	return domain.Ride{ID: item.ID, PassengerID: item.PassengerID, DriverID: driverID, Status: item.Status, FareCentavos: item.FareCentavos, RideType: item.RideType, PickupLatitude: item.PickupLatitude, PickupLongitude: item.PickupLongitude, PickupName: item.PickupName, DropoffLatitude: item.DropoffLatitude, DropoffLongitude: item.DropoffLongitude, DropoffName: item.DropoffName, DistanceKm: item.DistanceKm, DurationMinutes: item.DurationMinutes, DriverName: item.DriverName, VehicleType: item.VehicleType, PlateNumber: item.PlateNumber, DriverRating: item.DriverRating, CompletedAt: completedAt, PaymentStatus: item.PaymentStatus, CommissionCentavos: item.CommissionCentavos, DriverPayoutCentavos: item.DriverPayoutCentavos}
}
func fromBid(item *ent.Bid) domain.Bid {
	return domain.Bid{ID: item.ID, RideID: item.RideID, DriverID: item.DriverID, FareCentavos: item.OfferedFareCentavos, Status: item.Status}
}

func fromSession(item *ent.BidSession) domain.BidSession {
	var targetDriverID, acceptedDriverID *int
	if item.TargetDriverID != 0 {
		value := item.TargetDriverID
		targetDriverID = &value
	}
	if item.AcceptedDriverID != 0 {
		value := item.AcceptedDriverID
		acceptedDriverID = &value
	}
	return domain.BidSession{ID: item.ID, PassengerID: item.PassengerID, RideType: item.RideType, PickupLatitude: item.PickupLatitude, PickupLongitude: item.PickupLongitude, PickupName: item.PickupName, DropoffLatitude: item.DropoffLatitude, DropoffLongitude: item.DropoffLongitude, DropoffName: item.DropoffName, DistanceKm: item.DistanceKm, DurationMinutes: item.DurationMinutes, OfferedFareCentavos: item.OfferedFareCentavos, Status: item.Status, TargetDriverID: targetDriverID, AcceptedDriverID: acceptedDriverID, ExpiresAt: item.ExpiresAt, CreatedAt: item.CreatedAt}
}

func fromOffer(item *ent.BidOffer) domain.BidOffer {
	return domain.BidOffer{ID: int64(item.ID), SessionID: item.SessionID, DriverID: item.DriverID, DriverName: item.DriverName, PlateNumber: item.PlateNumber, VehicleType: item.VehicleType, ProposedFareCentavos: item.ProposedFareCentavos, Status: item.Status, CreatedAt: item.CreatedAt}
}

func fromReview(item *ent.Review) domain.Review {
	return domain.Review{ID: item.ID, RideID: item.RideID, DriverID: item.DriverID, PassengerID: item.PassengerID, PassengerName: item.PassengerName, Rating: item.Rating, Comment: item.Comment, CreatedAt: item.CreatedAt.UTC().Format(time.RFC3339)}
}

func fromPassengerReview(item *ent.PassengerReview) domain.PassengerReview {
	return domain.PassengerReview{ID: item.ID, RideID: item.RideID, DriverID: item.DriverID, PassengerID: item.PassengerID, Rating: item.Rating, Comment: item.Comment, CreatedAt: item.CreatedAt.UTC().Format(time.RFC3339)}
}
