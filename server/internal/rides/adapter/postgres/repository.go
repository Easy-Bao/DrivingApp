package postgres

import (
	"context"
	"database/sql"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/bid"
	"github.com/Easy-Bao/DrivingApp/server/ent/bidoffer"
	"github.com/Easy-Bao/DrivingApp/server/ent/bidsession"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/review"
	"github.com/Easy-Bao/DrivingApp/server/ent/ride"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type Repository struct{ client *ent.Client }

func NewRepository(client *ent.Client) *Repository { return &Repository{client: client} }
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
	item, err := repository.client.Bid.Create().SetRideID(value.RideID).SetDriverID(value.DriverID).SetOfferedFareCentavos(value.FareCentavos).SetStatus(value.Status).Save(ctx)
	if err != nil {
		return domain.Bid{}, err
	}
	return fromBid(item), nil
}
func (repository *Repository) Get(ctx context.Context, id int) (domain.Ride, error) {
	item, err := repository.client.Ride.Get(ctx, id)
	if err != nil {
		return domain.Ride{}, err
	}
	return fromRide(item), nil
}
func (repository *Repository) AcceptBid(ctx context.Context, bidID, driverID int) (domain.Bid, domain.Ride, error) {
	transaction, err := repository.client.Tx(ctx)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	offer, err := transaction.Bid.Query().Where(bid.IDEQ(bidID), bid.DriverIDEQ(driverID), bid.StatusEQ("pending")).Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	updated, err := offer.Update().SetStatus("accepted").Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	trip, err := transaction.Ride.Get(ctx, offer.RideID)
	if err != nil {
		_ = transaction.Rollback()
		return domain.Bid{}, domain.Ride{}, err
	}
	trip, err = trip.Update().SetStatus("assigned").SetDriverID(driverID).Save(ctx)
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
	updated, err := item.Update().SetDriverID(driverID).SetStatus("accepted").Save(ctx)
	if err != nil {
		return domain.Ride{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.Ride{}, err
	}
	return fromRide(updated), nil
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
	}
	items, err := query.Order(bidsession.ByCreatedAt()).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.BidSession, 0, len(items))
	for _, item := range items {
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

func (repository *Repository) AcceptOffer(ctx context.Context, sessionID, offerID, driverID int) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	transaction, err := repository.client.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	session, err := transaction.BidSession.Query().Where(bidsession.IDEQ(sessionID), bidsession.StatusEQ("open"), bidsession.ExpiresAtGT(time.Now())).Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	if session.TargetDriverID != 0 && session.TargetDriverID != driverID {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	offerQuery := transaction.BidOffer.Query().Where(bidoffer.IDEQ(offerID), bidoffer.SessionIDEQ(sessionID), bidoffer.DriverIDEQ(driverID), bidoffer.StatusEQ("pending"))
	offer, err := offerQuery.Only(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	profile, err := transaction.DriverProfile.Query().Where(driverprofile.UserIDEQ(driverID), driverprofile.IsOnlineEQ(true)).Only(ctx)
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
	updatedSession, err := session.Update().SetStatus("accepted").SetAcceptedDriverID(driverID).Save(ctx)
	if err != nil {
		_ = transaction.Rollback()
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	rideItem, err := transaction.Ride.Create().SetPassengerID(session.PassengerID).SetDriverID(driverID).SetStatus("accepted").SetFareCentavos(session.OfferedFareCentavos).SetRideType(session.RideType).SetPickupLatitude(session.PickupLatitude).SetPickupLongitude(session.PickupLongitude).SetPickupName(session.PickupName).SetDropoffLatitude(session.DropoffLatitude).SetDropoffLongitude(session.DropoffLongitude).SetDropoffName(session.DropoffName).SetDistanceKm(session.DistanceKm).SetDurationMinutes(session.DurationMinutes).SetDriverName(profile.Name).SetVehicleType(profile.VehicleType).SetPlateNumber(profile.PlateNumber).Save(ctx)
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
	return result, nil
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
	return result, nil
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
	item, err := repository.client.Review.Create().SetDriverID(value.DriverID).SetPassengerID(value.PassengerID).SetPassengerName(value.PassengerName).SetRating(value.Rating).SetComment(value.Comment).Save(ctx)
	if err != nil {
		return domain.Review{}, err
	}
	return fromReview(item), nil
}

func (repository *Repository) OnlineDrivers(ctx context.Context) ([]domain.OnlineDriver, error) {
	items, err := repository.client.DriverProfile.Query().Where(driverprofile.IsOnlineEQ(true)).Order(driverprofile.ByID()).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.OnlineDriver, 0, len(items))
	for _, item := range items {
		result = append(result, domain.OnlineDriver{ID: item.UserID, UserID: item.UserID, Name: item.Name, VehicleType: item.VehicleType, PlateNumber: item.PlateNumber, Rating: item.Rating})
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
	return domain.Ride{ID: item.ID, PassengerID: item.PassengerID, DriverID: driverID, Status: item.Status, FareCentavos: item.FareCentavos, RideType: item.RideType, PickupLatitude: item.PickupLatitude, PickupLongitude: item.PickupLongitude, PickupName: item.PickupName, DropoffLatitude: item.DropoffLatitude, DropoffLongitude: item.DropoffLongitude, DropoffName: item.DropoffName, DistanceKm: item.DistanceKm, DurationMinutes: item.DurationMinutes, DriverName: item.DriverName, VehicleType: item.VehicleType, PlateNumber: item.PlateNumber, DriverRating: item.DriverRating, CompletedAt: completedAt}
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
	return domain.Review{ID: item.ID, DriverID: item.DriverID, PassengerID: item.PassengerID, PassengerName: item.PassengerName, Rating: item.Rating, Comment: item.Comment, CreatedAt: item.CreatedAt.UTC().Format(time.RFC3339)}
}
