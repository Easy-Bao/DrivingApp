package rides_test

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	"testing"
)

type repository struct{}

func (repository) CreateRide(_ context.Context, ride domain.Ride) (domain.Ride, error) {
	ride.ID = 1
	return ride, nil
}
func (repository) CreateBid(_ context.Context, bid domain.Bid) (domain.Bid, error) {
	bid.ID = 1
	return bid, nil
}
func (repository) AcceptBid(context.Context, int, int) (domain.Bid, domain.Ride, error) {
	return domain.Bid{Status: "accepted"}, domain.Ride{Status: "assigned"}, nil
}
func (repository) Get(context.Context, int) (domain.Ride, error) { return domain.Ride{}, nil }
func TestFareUsesIntegerCentavos(t *testing.T) {
	if got := usecase.CalculateFare(5, 10); got != 3500 {
		t.Fatalf("fare = %d", got)
	}
}
func TestRideServiceDelegatesCreation(t *testing.T) {
	ride, err := usecase.NewService(repository{}).CreateRide(context.Background(), 2, 2500)
	if err != nil || ride.Status != "requested" {
		t.Fatalf("ride = %#v, %v", ride, err)
	}
}
