package usecase

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type Service struct{ repository domain.Repository }

func NewService(repository domain.Repository) *Service { return &Service{repository: repository} }
func (service *Service) CreateRide(ctx context.Context, passengerID int, fareCentavos int64) (domain.Ride, error) {
	return service.repository.CreateRide(ctx, domain.Ride{PassengerID: passengerID, Status: "requested", FareCentavos: fareCentavos})
}
func (service *Service) SubmitBid(ctx context.Context, rideID, driverID int, fareCentavos int64) (domain.Bid, error) {
	return service.repository.CreateBid(ctx, domain.Bid{RideID: rideID, DriverID: driverID, FareCentavos: fareCentavos, Status: "pending"})
}
func (service *Service) AcceptBid(ctx context.Context, bidID, driverID int) (domain.Bid, domain.Ride, error) {
	return service.repository.AcceptBid(ctx, bidID, driverID)
}
func (service *Service) Get(ctx context.Context, id int) (domain.Ride, error) {
	return service.repository.Get(ctx, id)
}
func CalculateFare(distanceKm, durationMinutes float64) int64 {
	total := 2500 + distanceKm*100 + durationMinutes*50
	if total < 2500 {
		return 2500
	}
	return int64(total)
}
