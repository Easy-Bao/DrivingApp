package postgres

import (
	"context"
	"fmt"
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

var activeRideStatuses = []string{
	string(domain.RideRequested),
	string(domain.RideAssigned),
	string(domain.RideAccepted),
	string(domain.RideArrived),
	string(domain.RideInTransit),
}

func NewRepository(client *ent.Client, platformCommissionBPS int64) *Repository {
	return &Repository{client: client, platformCommissionBPS: platformCommissionBPS}
}
func (repository *Repository) CreateRide(ctx context.Context, value domain.Ride) (domain.Ride, error) {
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
	builder := repository.client.Ride.Create().SetPassengerID(value.PassengerID).SetStatus(string(normalizedStatus)).SetFareCentavos(value.FareCentavos).SetRideType(value.RideType)
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
	if value.RideID <= 0 || value.DriverID <= 0 || value.FareCentavos <= 0 {
		return domain.Bid{}, domain.ErrInvalidFareOffer
	}
	if value.Status == "" {
		value.Status = "pending"
	}
	if value.Status != "pending" {
		return domain.Bid{}, domain.ErrInvalidFareOffer
	}
	transaction, err := repository.client.Tx(ctx)
	if err != nil {
		return domain.Bid{}, err
	}
	defer transaction.Rollback()
	if _, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(value.DriverID), driverprofile.IsOnlineEQ(true)).ForUpdate().Only(ctx); err != nil {
		return domain.Bid{}, domain.ErrDriverUnavailable
	}
	if _, err := transaction.Ride.Query().Where(ride.IDEQ(value.RideID), ride.StatusEQ("requested")).ForUpdate().Only(ctx); err != nil {
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
		if ent.IsConstraintError(err) {
			return domain.Bid{}, domain.ErrDuplicateBid
		}
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

func (repository *Repository) ActiveRidesForDriver(ctx context.Context, driverID int) ([]domain.Ride, error) {
	items, err := repository.client.Ride.Query().Where(
		ride.DriverIDEQ(driverID),
		ride.StatusIn(activeRideStatuses...),
	).Order(ride.ByID()).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Ride, 0, len(items))
	for _, item := range items {
		result = append(result, fromRide(item))
	}
	return result, nil
}
func (repository *Repository) AcceptBid(ctx context.Context, bidID, driverID int) (domain.Bid, domain.Ride, error) {
	transaction, err := repository.client.Tx(ctx)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	offer, err := transaction.Bid.Query().Where(bid.IDEQ(bidID), bid.DriverIDEQ(driverID), bid.StatusEQ("pending")).ForUpdate().Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(driverID), driverprofile.IsOnlineEQ(true)).ForUpdate().Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, domain.ErrDriverUnavailable
	}
	active, err := transaction.Ride.Query().Where(ride.DriverIDEQ(profile.UserID), ride.StatusIn(activeRideStatuses...)).Count(ctx)
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
	trip, err := transaction.Ride.Query().Where(ride.IDEQ(offer.RideID), ride.StatusEQ("requested")).ForUpdate().Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	settlement, err := domain.NewSettlementSnapshot(
		trip.FareCentavos,
		repository.platformCommissionBPS,
	)
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
		SetCommissionBps(settlement.CommissionBPS).
		SetCommissionCentavos(settlement.CommissionCentavos).
		SetDriverPayoutCentavos(settlement.DriverPayoutCentavos).
		Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	if err := createRideSettlement(ctx, transaction, trip.ID, settlement); err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	return fromBid(updated), fromRide(trip), nil
}

func (repository *Repository) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	transaction, err := repository.client.Tx(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	defer transaction.Rollback()
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(driverID), driverprofile.IsOnlineEQ(true)).ForUpdate().Only(ctx)
	if err != nil {
		return domain.Ride{}, domain.ErrDriverUnavailable
	}
	item, err := transaction.Ride.Query().Where(ride.IDEQ(rideID), ride.StatusEQ("requested")).ForUpdate().Only(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	active, err := transaction.Ride.Query().Where(ride.DriverIDEQ(driverID), ride.StatusIn(activeRideStatuses...)).Count(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if active >= 5 {
		return domain.Ride{}, domain.ErrDriverAtCapacity
	}
	settlement, err := domain.NewSettlementSnapshot(
		item.FareCentavos,
		repository.platformCommissionBPS,
	)
	if err != nil {
		return domain.Ride{}, err
	}
	updated, err := item.Update().
		SetDriverID(driverID).
		SetStatus("accepted").
		SetDriverName(profile.Name).
		SetVehicleType(profile.VehicleType).
		SetPlateNumber(profile.PlateNumber).
		SetCommissionBps(settlement.CommissionBPS).
		SetCommissionCentavos(settlement.CommissionCentavos).
		SetDriverPayoutCentavos(settlement.DriverPayoutCentavos).
		Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if err := createRideSettlement(ctx, transaction, updated.ID, settlement); err != nil {
		return domain.Ride{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.Ride{}, err
	}
	return fromRide(updated), nil
}

func (repository *Repository) SettleCash(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	transaction, err := repository.client.Tx(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	defer transaction.Rollback()
	rideItem, err := transaction.Ride.Query().Where(ride.IDEQ(rideID), ride.DriverIDEQ(driverID), ride.StatusEQ("completed")).ForUpdate().Only(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	settlementRecord, settlement, err := ensureRideSettlement(
		ctx,
		transaction,
		rideItem,
		repository.platformCommissionBPS,
	)
	if err != nil {
		return domain.Ride{}, err
	}
	if settlementRecord.PaymentStatus == "paid" {
		if rideItem.PaymentStatus != "paid" {
			rideItem, err = rideItem.Update().
				SetPaymentStatus("paid").
				SetNillableCashReceivedAt(settlementRecord.CashReceivedAt).
				SetNillableCommissionBps(settlementRecord.CommissionBps).
				SetCommissionCentavos(settlementRecord.CommissionCentavos).
				SetDriverPayoutCentavos(settlementRecord.DriverPayoutCentavos).
				Save(ctx)
			if err != nil {
				return domain.Ride{}, err
			}
		}
		if err := transaction.Commit(); err != nil {
			return domain.Ride{}, err
		}
		return fromRide(rideItem), nil
	}
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(driverID)).Only(ctx)
	if err != nil {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	commission := settlement.CommissionCentavos
	payout := settlement.DriverPayoutCentavos
	if payout <= 0 {
		return domain.Ride{}, domain.ErrInvalidFareOffer
	}
	_, err = transaction.WalletLedger.Create().SetDriverID(driverID).SetRideID(rideID).SetAmountCentavos(payout).SetCommissionCentavos(commission).SetKind("cash_trip").Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if err := creditDriverWallet(ctx, transaction, profile, payout); err != nil {
		return domain.Ride{}, err
	}
	settledAt := time.Now()
	if _, err := settlementRecord.Update().
		SetPaymentStatus("paid").
		SetCashReceivedAt(settledAt).
		SetSettledAt(settledAt).
		SetCommissionBps(settlement.CommissionBPS).
		SetCommissionCentavos(commission).
		SetDriverPayoutCentavos(payout).
		Save(ctx); err != nil {
		return domain.Ride{}, err
	}
	updatedRide, err := rideItem.Update().
		SetPaymentStatus("paid").
		SetCashReceivedAt(settledAt).
		SetCommissionBps(settlement.CommissionBPS).
		SetCommissionCentavos(commission).
		SetDriverPayoutCentavos(payout).
		Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.Ride{}, err
	}
	return fromRide(updatedRide), nil
}

func (repository *Repository) UpdateStatus(ctx context.Context, rideID, actorID int, currentStatus, status string) (domain.Ride, error) {
	current, currentOK := domain.NormalizeRideStatus(currentStatus)
	next, nextOK := domain.NormalizeRideStatus(status)
	if !currentOK || !nextOK {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	update := repository.client.Ride.UpdateOneID(rideID).Where(ride.StatusEQ(string(current)), ride.Or(ride.PassengerIDEQ(actorID), ride.DriverIDEQ(actorID))).SetStatus(string(next))
	if domain.IsTerminal(string(next)) {
		update.SetCompletedAt(time.Now())
	}
	item, err := update.Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	return fromRide(item), nil
}

func (repository *Repository) CreateSession(ctx context.Context, value domain.BidSession) (domain.BidSession, error) {
	transaction, err := repository.client.Tx(ctx)
	if err != nil {
		return domain.BidSession{}, err
	}
	defer transaction.Rollback()
	now := time.Now()
	if _, err := transaction.User.Query().Where(user.IDEQ(value.PassengerID)).ForUpdate().Only(ctx); err != nil {
		return domain.BidSession{}, err
	}
	if _, err := transaction.BidSession.Update().Where(
		bidsession.PassengerIDEQ(value.PassengerID),
		bidsession.StatusEQ("open"),
		bidsession.ExpiresAtLTE(now),
	).SetStatus("expired").Save(ctx); err != nil {
		return domain.BidSession{}, err
	}
	activeSession, err := transaction.BidSession.Query().Where(bidsession.PassengerIDEQ(value.PassengerID), bidsession.StatusEQ("open"), bidsession.ExpiresAtGT(now)).Exist(ctx)
	if err != nil {
		return domain.BidSession{}, err
	}
	if activeSession {
		return domain.BidSession{}, domain.ErrActiveBooking
	}
	activeRide, err := transaction.Ride.Query().Where(ride.PassengerIDEQ(value.PassengerID), ride.StatusIn(activeRideStatuses...)).Exist(ctx)
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
		SetPassengerNote(value.PassengerNote).
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
		if ent.IsConstraintError(err) {
			return domain.BidSession{}, domain.ErrActiveBooking
		}
		return domain.BidSession{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.BidSession{}, err
	}
	return fromSession(item), nil
}

func (repository *Repository) ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error) {
	now := time.Now()
	query := repository.client.BidSession.Query().Where(bidsession.StatusEQ("open"), bidsession.ExpiresAtGT(now))
	pendingSessionIDs := map[int]struct{}{}
	if driverID != nil {
		profile, err := repository.client.DriverProfile.Query().Where(driverprofile.UserIDEQ(*driverID), driverprofile.IsOnlineEQ(true)).Only(ctx)
		if err != nil {
			return nil, domain.ErrDriverUnavailable
		}
		active, err := repository.client.Ride.Query().Where(ride.DriverIDEQ(profile.UserID), ride.StatusIn(activeRideStatuses[1:]...)).Count(ctx)
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
	transaction, err := repository.client.Tx(ctx)
	if err != nil {
		return domain.BidOffer{}, err
	}
	defer transaction.Rollback()
	now := time.Now()
	session, err := transaction.BidSession.Query().Where(
		bidsession.IDEQ(value.SessionID),
		bidsession.StatusEQ("open"),
		bidsession.ExpiresAtGT(now),
	).ForUpdate().Only(ctx)
	if err != nil {
		return domain.BidOffer{}, domain.ErrDriverUnavailable
	}
	if session.TargetDriverID != 0 && session.TargetDriverID != value.DriverID {
		return domain.BidOffer{}, domain.ErrDriverUnavailable
	}
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(value.DriverID), driverprofile.IsOnlineEQ(true)).ForUpdate().Only(ctx)
	if err != nil {
		return domain.BidOffer{}, domain.ErrDriverUnavailable
	}
	active, err := transaction.Ride.Query().Where(ride.DriverIDEQ(profile.UserID), ride.StatusIn(activeRideStatuses...)).Count(ctx)
	if err != nil {
		return domain.BidOffer{}, err
	}
	if active >= 5 {
		return domain.BidOffer{}, domain.ErrDriverAtCapacity
	}
	existing, err := transaction.BidOffer.Query().Where(bidoffer.SessionIDEQ(value.SessionID), bidoffer.DriverIDEQ(value.DriverID), bidoffer.StatusEQ("pending")).Exist(ctx)
	if err != nil {
		return domain.BidOffer{}, err
	}
	if existing {
		return domain.BidOffer{}, domain.ErrDuplicateBid
	}
	builder := transaction.BidOffer.Create().SetSessionID(value.SessionID).SetDriverID(value.DriverID).SetDriverName(profile.Name).SetPlateNumber(profile.PlateNumber).SetVehicleType(profile.VehicleType).SetProposedFareCentavos(value.ProposedFareCentavos).SetStatus("pending")
	item, err := builder.Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			return domain.BidOffer{}, domain.ErrDuplicateBid
		}
		return domain.BidOffer{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.BidOffer{}, err
	}
	return fromOffer(item), nil
}

func (repository *Repository) AcceptOffer(ctx context.Context, sessionID, offerID, passengerID int) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	transaction, err := repository.client.Tx(ctx)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	defer transaction.Rollback()
	now := time.Now()
	session, err := transaction.BidSession.Query().Where(bidsession.IDEQ(sessionID), bidsession.StatusEQ("open"), bidsession.ExpiresAtGT(now)).ForUpdate().Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if session.PassengerID != passengerID {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	offerQuery := transaction.BidOffer.Query().Where(bidoffer.IDEQ(offerID), bidoffer.SessionIDEQ(sessionID), bidoffer.StatusEQ("pending")).ForUpdate()
	offer, err := offerQuery.Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if session.TargetDriverID != 0 && session.TargetDriverID != offer.DriverID {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(offer.DriverID), driverprofile.IsOnlineEQ(true)).ForUpdate().Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrDriverUnavailable
	}
	activeDriverRides, err := transaction.Ride.Query().Where(ride.DriverIDEQ(profile.UserID), ride.StatusIn(activeRideStatuses...)).Count(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if activeDriverRides >= 5 {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrDriverAtCapacity
	}
	activePassengerRide, err := transaction.Ride.Query().Where(ride.PassengerIDEQ(session.PassengerID), ride.StatusIn(activeRideStatuses...)).Exist(ctx)
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
	acceptedRide, err := domain.NewRideFromAcceptedOffer(
		fromSession(session),
		fromOffer(offer),
		domain.DriverAssignmentSnapshot{
			Name:        profile.Name,
			VehicleType: profile.VehicleType,
			PlateNumber: profile.PlateNumber,
		},
		repository.platformCommissionBPS,
	)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	rideItem, err := transaction.Ride.Create().
		SetPassengerID(acceptedRide.PassengerID).
		SetDriverID(*acceptedRide.DriverID).
		SetStatus(acceptedRide.Status).
		SetFareCentavos(acceptedRide.FareCentavos).
		SetRideType(acceptedRide.RideType).
		SetPickupLatitude(acceptedRide.PickupLatitude).
		SetPickupLongitude(acceptedRide.PickupLongitude).
		SetPickupName(acceptedRide.PickupName).
		SetDropoffLatitude(acceptedRide.DropoffLatitude).
		SetDropoffLongitude(acceptedRide.DropoffLongitude).
		SetDropoffName(acceptedRide.DropoffName).
		SetDistanceKm(acceptedRide.DistanceKm).
		SetDurationMinutes(acceptedRide.DurationMinutes).
		SetDriverName(acceptedRide.DriverName).
		SetVehicleType(acceptedRide.VehicleType).
		SetPlateNumber(acceptedRide.PlateNumber).
		SetCommissionBps(*acceptedRide.CommissionBPS).
		SetCommissionCentavos(acceptedRide.CommissionCentavos).
		SetDriverPayoutCentavos(acceptedRide.DriverPayoutCentavos).
		Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if err := createRideSettlement(
		ctx,
		transaction,
		rideItem.ID,
		domain.SettlementSnapshot{
			FareCentavos:         acceptedRide.FareCentavos,
			CommissionBPS:        *acceptedRide.CommissionBPS,
			CommissionCentavos:   acceptedRide.CommissionCentavos,
			DriverPayoutCentavos: acceptedRide.DriverPayoutCentavos,
		},
	); err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	return fromSession(updatedSession), fromOffer(updatedOffer), fromRide(rideItem), nil
}

func (repository *Repository) CancelSession(ctx context.Context, sessionID, passengerID int) (domain.BidSession, error) {
	item, err := repository.client.BidSession.UpdateOneID(sessionID).Where(bidsession.PassengerIDEQ(passengerID), bidsession.StatusEQ("open")).SetStatus("cancelled").Save(ctx)
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

func (repository *Repository) DriverStats(ctx context.Context, driverID int, dayStart, dayEnd time.Time) (domain.DriverStats, error) {
	rideMetrics, err := aggregateDriverRideMetrics(
		ctx,
		repository.client.Ride.Query().Where(ride.DriverIDEQ(driverID)),
		dayStart,
		dayEnd,
	)
	if err != nil {
		return domain.DriverStats{}, err
	}
	var ratingRows []struct {
		AverageRating *float64 `json:"average_rating"`
	}
	if err := repository.client.Review.Query().Where(review.DriverIDEQ(driverID)).Aggregate(
		ent.As(ent.Mean(review.FieldRating), "average_rating"),
	).Scan(ctx, &ratingRows); err != nil {
		return domain.DriverStats{}, err
	}
	var averageRating float64
	if len(ratingRows) > 0 && ratingRows[0].AverageRating != nil {
		averageRating = *ratingRows[0].AverageRating
	}
	return domain.DriverStats{
		DriverID:            driverID,
		TotalTrips:          int(rideMetrics.TotalTrips),
		CompletedTrips:      int(rideMetrics.CompletedTrips),
		ActiveTrips:         int(rideMetrics.ActiveTrips),
		TotalEarnings:       rideMetrics.TotalEarningsCentavos,
		TodayCompletedTrips: int(rideMetrics.TodayCompletedTrips),
		TodayEarnings:       rideMetrics.TodayEarningsCentavos,
		AverageRating:       averageRating,
	}, nil
}

func (repository *Repository) DriverEarnings(ctx context.Context, driverID int, monthStart, monthEnd time.Time) ([]domain.DriverEarning, error) {
	items, err := repository.client.Ride.Query().Where(
		ride.DriverIDEQ(driverID),
		ride.StatusEQ("completed"),
		ride.Or(
			ride.And(ride.CompletedAtNotNil(), ride.CompletedAtGTE(monthStart), ride.CompletedAtLT(monthEnd)),
			ride.And(ride.CompletedAtIsNil(), ride.CreatedAtGTE(monthStart), ride.CreatedAtLT(monthEnd)),
		),
	).Select(
		ride.FieldCreatedAt,
		ride.FieldCompletedAt,
		ride.FieldDriverPayoutCentavos,
	).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.DriverEarning, 0, len(items))
	for _, item := range items {
		completedAt := item.CompletedAt
		if completedAt.IsZero() {
			completedAt = item.CreatedAt
		}
		result = append(result, domain.DriverEarning{
			CompletedAt: completedAt, PayoutCentavos: item.DriverPayoutCentavos,
		})
	}
	return result, nil
}

type driverRideMetrics struct {
	TotalTrips            int64 `json:"total_trips"`
	CompletedTrips        int64 `json:"completed_trips"`
	ActiveTrips           int64 `json:"active_trips"`
	TotalEarningsCentavos int64 `json:"total_earnings_centavos"`
	TodayCompletedTrips   int64 `json:"today_completed_trips"`
	TodayEarningsCentavos int64 `json:"today_earnings_centavos"`
}

func aggregateDriverRideMetrics(ctx context.Context, query *ent.RideQuery, dayStart, dayEnd time.Time) (driverRideMetrics, error) {
	startLiteral := dayStart.UTC().Format(time.RFC3339Nano)
	endLiteral := dayEnd.UTC().Format(time.RFC3339Nano)
	var rows []driverRideMetrics
	if err := query.Aggregate(
		ent.As(ent.Count(), "total_trips"),
		driverRideAggregate("completed_trips", func(selector *entsql.Selector) string {
			return fmt.Sprintf("COUNT(*) FILTER (WHERE %s = 'completed')", selector.C(ride.FieldStatus))
		}),
		driverRideAggregate("active_trips", func(selector *entsql.Selector) string {
			return fmt.Sprintf("COUNT(*) FILTER (WHERE %s IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit'))", selector.C(ride.FieldStatus))
		}),
		driverRideAggregate("total_earnings_centavos", func(selector *entsql.Selector) string {
			return fmt.Sprintf("COALESCE(SUM(%s) FILTER (WHERE %s = 'completed'), 0)", selector.C(ride.FieldDriverPayoutCentavos), selector.C(ride.FieldStatus))
		}),
		driverRideAggregate("today_completed_trips", func(selector *entsql.Selector) string {
			return fmt.Sprintf("COUNT(*) FILTER (WHERE %s)", completedDuring(selector, startLiteral, endLiteral))
		}),
		driverRideAggregate("today_earnings_centavos", func(selector *entsql.Selector) string {
			return fmt.Sprintf("COALESCE(SUM(%s) FILTER (WHERE %s), 0)", selector.C(ride.FieldDriverPayoutCentavos), completedDuring(selector, startLiteral, endLiteral))
		}),
	).Scan(ctx, &rows); err != nil {
		return driverRideMetrics{}, err
	}
	if len(rows) == 0 {
		return driverRideMetrics{}, nil
	}
	return rows[0], nil
}

func driverRideAggregate(alias string, expression func(*entsql.Selector) string) ent.AggregateFunc {
	return func(selector *entsql.Selector) string {
		return entsql.As(expression(selector), alias)
	}
}

func completedDuring(selector *entsql.Selector, start, end string) string {
	statusColumn := selector.C(ride.FieldStatus)
	completedColumn := selector.C(ride.FieldCompletedAt)
	createdColumn := selector.C(ride.FieldCreatedAt)
	return fmt.Sprintf(
		"%s = 'completed' AND ((%s >= TIMESTAMPTZ '%s' AND %s < TIMESTAMPTZ '%s') OR (%s IS NULL AND %s >= TIMESTAMPTZ '%s' AND %s < TIMESTAMPTZ '%s'))",
		statusColumn,
		completedColumn,
		start,
		completedColumn,
		end,
		completedColumn,
		createdColumn,
		start,
		createdColumn,
		end,
	)
}

func (repository *Repository) DriverTrips(ctx context.Context, driverID int, history domain.TripHistoryQuery) ([]domain.Ride, error) {
	query := repository.client.Ride.Query().Where(ride.DriverIDEQ(driverID))
	if history.ActiveOnly {
		query = query.Where(ride.StatusIn(activeRideStatuses[1:]...))
	}
	items, err := query.
		Order(ride.ByCreatedAt(entsql.OrderDesc()), ride.ByID(entsql.OrderDesc())).
		Limit(history.Limit + 1).
		Offset(history.Offset).
		All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Ride, 0, len(items))
	for _, item := range items {
		result = append(result, fromRide(item))
	}
	hydrated, err := repository.hydrateDriverDetails(ctx, result)
	if err != nil {
		return nil, err
	}
	return repository.hydratePassengerDetails(ctx, hydrated)
}

func (repository *Repository) PassengerRides(ctx context.Context, passengerID int, history domain.TripHistoryQuery) ([]domain.Ride, error) {
	items, err := repository.client.Ride.Query().
		Where(ride.PassengerIDEQ(passengerID)).
		Order(ride.ByCreatedAt(entsql.OrderDesc()), ride.ByID(entsql.OrderDesc())).
		Limit(history.Limit + 1).
		Offset(history.Offset).
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

func (repository *Repository) PassengerActivitySummary(ctx context.Context, passengerID int, weekStart, weekEnd time.Time) (domain.PassengerActivitySummary, error) {
	startLiteral := weekStart.UTC().Format(time.RFC3339Nano)
	endLiteral := weekEnd.UTC().Format(time.RFC3339Nano)
	var rows []struct {
		FareCentavos   int64 `json:"fare_centavos"`
		CompletedRides int64 `json:"completed_rides"`
	}
	err := repository.client.Ride.Query().Where(ride.PassengerIDEQ(passengerID)).Aggregate(
		driverRideAggregate("fare_centavos", func(selector *entsql.Selector) string {
			return fmt.Sprintf("COALESCE(SUM(%s) FILTER (WHERE %s), 0)", selector.C(ride.FieldFareCentavos), completedDuring(selector, startLiteral, endLiteral))
		}),
		driverRideAggregate("completed_rides", func(selector *entsql.Selector) string {
			return fmt.Sprintf("COUNT(*) FILTER (WHERE %s)", completedDuring(selector, startLiteral, endLiteral))
		}),
	).Scan(ctx, &rows)
	if err != nil {
		return domain.PassengerActivitySummary{}, err
	}
	if len(rows) == 0 {
		return domain.PassengerActivitySummary{}, nil
	}
	return domain.PassengerActivitySummary{
		ThisWeekFareCentavos:   rows[0].FareCentavos,
		ThisWeekCompletedRides: int(rows[0].CompletedRides),
	}, nil
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
	rideIDs := make([]int, 0, len(rides))
	seen := make(map[int]struct{})
	for _, item := range rides {
		if item.ID > 0 {
			rideIDs = append(rideIDs, item.ID)
		}
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

	reviewsByRideID := make(map[int]*ent.Review, len(rideIDs))
	if len(rideIDs) > 0 {
		reviews, reviewErr := repository.client.Review.Query().Where(
			review.RideIDIn(rideIDs...),
		).All(ctx)
		if reviewErr != nil {
			return nil, reviewErr
		}
		for _, item := range reviews {
			reviewsByRideID[item.RideID] = item
		}
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
		if tripReview := reviewsByRideID[rides[index].ID]; tripReview != nil {
			rides[index].PassengerRating = tripReview.Rating
			rides[index].PassengerFeedback = strings.TrimSpace(tripReview.Comment)
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
	passengerIDs := make([]int, 0, len(items))
	seenPassengerIDs := make(map[int]struct{}, len(items))
	for _, item := range items {
		if item.PassengerID <= 0 {
			continue
		}
		if _, exists := seenPassengerIDs[item.PassengerID]; exists {
			continue
		}
		seenPassengerIDs[item.PassengerID] = struct{}{}
		passengerIDs = append(passengerIDs, item.PassengerID)
	}
	passengerNames, err := repository.passengerNames(ctx, passengerIDs)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Review, 0, len(items))
	for index := len(items) - 1; index >= 0; index-- {
		item := fromReview(items[index])
		if strings.TrimSpace(item.PassengerName) == "" {
			item.PassengerName = passengerNames[item.PassengerID]
		}
		result = append(result, item)
	}
	return result, nil
}

func (repository *Repository) passengerNames(ctx context.Context, passengerIDs []int) (map[int]string, error) {
	names := make(map[int]string, len(passengerIDs))
	if len(passengerIDs) == 0 {
		return names, nil
	}
	accounts, err := repository.client.User.Query().Where(user.IDIn(passengerIDs...)).All(ctx)
	if err != nil {
		return nil, err
	}
	for _, account := range accounts {
		names[account.ID] = strings.TrimSpace(account.Name)
	}
	profiles, err := repository.client.PassengerProfile.Query().Where(
		passengerprofile.UserIDIn(passengerIDs...),
	).All(ctx)
	if err != nil {
		return nil, err
	}
	for _, profile := range profiles {
		if name := strings.TrimSpace(profile.Name); name != "" {
			names[profile.UserID] = name
		}
	}
	return names, nil
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
	if names, nameErr := repository.passengerNames(ctx, []int{value.PassengerID}); nameErr == nil {
		value.PassengerName = names[value.PassengerID]
	}
	item, err := repository.client.Review.Create().SetRideID(value.RideID).SetDriverID(value.DriverID).SetPassengerID(value.PassengerID).SetPassengerName(value.PassengerName).SetRating(value.Rating).SetComment(value.Comment).Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			return domain.Review{}, domain.ErrReviewAlreadySubmitted
		}
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
		if ent.IsConstraintError(err) {
			return domain.PassengerReview{}, domain.ErrReviewAlreadySubmitted
		}
		return domain.PassengerReview{}, err
	}
	return fromPassengerReview(item), nil
}

func (repository *Repository) OnlineDrivers(ctx context.Context, driverIDs []int) ([]domain.OnlineDriver, error) {
	items, err := repository.client.DriverProfile.Query().
		Where(driverprofile.IsOnlineEQ(true), driverprofile.UserIDIn(driverIDs...)).
		Order(driverprofile.ByID()).
		Limit(len(driverIDs)).
		All(ctx)
	if err != nil {
		return nil, err
	}
	availableIDs := make([]int, 0, len(items))
	for _, item := range items {
		availableIDs = append(availableIDs, item.UserID)
	}

	activePassengerCounts := make(map[int]int, len(availableIDs))
	if len(availableIDs) > 0 {
		var countRows []struct {
			DriverID int `json:"driver_id"`
			Count    int `json:"passenger_count"`
		}
		if err := repository.client.Ride.Query().Where(
			ride.DriverIDIn(availableIDs...),
			ride.StatusIn(activeRideStatuses[1:]...),
		).GroupBy(ride.FieldDriverID).Aggregate(
			ent.As(ent.Count(), "passenger_count"),
		).Scan(ctx, &countRows); err != nil {
			return nil, err
		}
		for _, row := range countRows {
			activePassengerCounts[row.DriverID] = row.Count
		}
	}

	ratings, err := repository.driverAverageRatings(ctx, availableIDs)
	if err != nil {
		return nil, err
	}

	result := make([]domain.OnlineDriver, 0, len(items))
	for _, item := range items {
		rating := item.Rating
		if average, exists := ratings[item.UserID]; exists {
			rating = average
		}
		result = append(result, domain.OnlineDriver{
			ID:                    item.UserID,
			UserID:                item.UserID,
			Name:                  item.Name,
			VehicleType:           item.VehicleType,
			PlateNumber:           item.PlateNumber,
			Rating:                rating,
			OnboardPassengerCount: activePassengerCounts[item.UserID],
		})
	}
	return result, nil
}

func (repository *Repository) PublicDriverSummaries(ctx context.Context, limit int) ([]domain.PublicDriverSummary, error) {
	profiles, err := repository.client.DriverProfile.Query().
		Where(driverprofile.IsOnlineEQ(true)).
		Order(driverprofile.ByID()).
		Limit(limit).
		All(ctx)
	if err != nil {
		return nil, err
	}
	driverIDs := make([]int, 0, len(profiles))
	for _, profile := range profiles {
		driverIDs = append(driverIDs, profile.UserID)
	}
	ratings, err := repository.driverAverageRatings(ctx, driverIDs)
	if err != nil {
		return nil, err
	}
	summaries := make([]domain.PublicDriverSummary, 0, len(profiles))
	for _, profile := range profiles {
		rating := profile.Rating
		if average, exists := ratings[profile.UserID]; exists {
			rating = average
		}
		summaries = append(summaries, domain.PublicDriverSummary{
			ID:          profile.UserID,
			Name:        profile.Name,
			VehicleType: profile.VehicleType,
			Rating:      rating,
		})
	}
	return summaries, nil
}

func (repository *Repository) driverAverageRatings(ctx context.Context, driverIDs []int) (map[int]float64, error) {
	ratings := make(map[int]float64, len(driverIDs))
	if len(driverIDs) == 0 {
		return ratings, nil
	}
	var rows []struct {
		DriverID      int      `json:"driver_id"`
		AverageRating *float64 `json:"average_rating"`
	}
	if err := repository.client.Review.Query().Where(
		review.DriverIDIn(driverIDs...),
	).GroupBy(review.FieldDriverID).Aggregate(
		ent.As(ent.Mean(review.FieldRating), "average_rating"),
	).Scan(ctx, &rows); err != nil {
		return nil, err
	}
	for _, row := range rows {
		if row.AverageRating != nil {
			ratings[row.DriverID] = *row.AverageRating
		}
	}
	return ratings, nil
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
	var createdAt *string
	if !item.CreatedAt.IsZero() {
		value := item.CreatedAt.UTC().Format(time.RFC3339)
		createdAt = &value
	}
	return domain.Ride{ID: item.ID, PassengerID: item.PassengerID, DriverID: driverID, Status: item.Status, FareCentavos: item.FareCentavos, RideType: item.RideType, PickupLatitude: item.PickupLatitude, PickupLongitude: item.PickupLongitude, PickupName: item.PickupName, DropoffLatitude: item.DropoffLatitude, DropoffLongitude: item.DropoffLongitude, DropoffName: item.DropoffName, DistanceKm: item.DistanceKm, DurationMinutes: item.DurationMinutes, DriverName: item.DriverName, VehicleType: item.VehicleType, PlateNumber: item.PlateNumber, DriverRating: item.DriverRating, CreatedAt: createdAt, CompletedAt: completedAt, PaymentStatus: item.PaymentStatus, CommissionBPS: item.CommissionBps, CommissionCentavos: item.CommissionCentavos, DriverPayoutCentavos: item.DriverPayoutCentavos}
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
	return domain.BidSession{ID: item.ID, PassengerID: item.PassengerID, RideType: item.RideType, PickupLatitude: item.PickupLatitude, PickupLongitude: item.PickupLongitude, PickupName: item.PickupName, DropoffLatitude: item.DropoffLatitude, DropoffLongitude: item.DropoffLongitude, DropoffName: item.DropoffName, PassengerNote: item.PassengerNote, DistanceKm: item.DistanceKm, DurationMinutes: item.DurationMinutes, OfferedFareCentavos: item.OfferedFareCentavos, Status: item.Status, TargetDriverID: targetDriverID, AcceptedDriverID: acceptedDriverID, ExpiresAt: item.ExpiresAt, CreatedAt: item.CreatedAt}
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
