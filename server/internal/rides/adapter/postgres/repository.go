package postgres

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/bid"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type Repository struct{ client *ent.Client }

func NewRepository(client *ent.Client) *Repository { return &Repository{client: client} }
func (repository *Repository) CreateRide(ctx context.Context, value domain.Ride) (domain.Ride, error) {
	item, err := repository.client.Ride.Create().SetPassengerID(value.PassengerID).SetStatus(value.Status).SetFareCentavos(value.FareCentavos).Save(ctx)
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
func fromRide(item *ent.Ride) domain.Ride {
	var driverID *int
	if item.DriverID != 0 {
		driverID = &item.DriverID
	}
	return domain.Ride{ID: item.ID, PassengerID: item.PassengerID, DriverID: driverID, Status: item.Status, FareCentavos: item.FareCentavos}
}
func fromBid(item *ent.Bid) domain.Bid {
	return domain.Bid{ID: item.ID, RideID: item.RideID, DriverID: item.DriverID, FareCentavos: item.OfferedFareCentavos, Status: item.Status}
}
