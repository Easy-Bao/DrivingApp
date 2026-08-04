package usecase

import (
	"context"
	"errors"

	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type Service struct{ repository domain.Repository }

func NewService(repository domain.Repository) *Service { return &Service{repository: repository} }
func (service *Service) CreateRide(ctx context.Context, passengerID int, fareCentavos int64) (domain.Ride, error) {
	return service.repository.CreateRide(ctx, domain.Ride{PassengerID: passengerID, Status: "requested", FareCentavos: fareCentavos, RideType: "Solo Ride"})
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

func (service *Service) CreateRideWithDetails(ctx context.Context, ride domain.Ride) (domain.Ride, error) {
	if ride.Status == "" {
		ride.Status = "requested"
	}
	if ride.RideType == "" {
		ride.RideType = "Solo Ride"
	}
	return service.repository.CreateRide(ctx, ride)
}

func (service *Service) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	repository, ok := service.repository.(domain.LifecycleRepository)
	if !ok {
		return domain.Ride{}, errors.New("ride lifecycle persistence is unavailable")
	}
	return repository.AcceptRide(ctx, rideID, driverID)
}

func (service *Service) UpdateStatus(ctx context.Context, rideID int, next string) (domain.Ride, error) {
	repository, ok := service.repository.(domain.LifecycleRepository)
	if !ok {
		return domain.Ride{}, errors.New("ride lifecycle persistence is unavailable")
	}
	current, err := service.repository.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, err
	}
	allowed := map[string]map[string]bool{
		"requested":  {"accepted": true, "canceled": true, "cancelled": true},
		"accepted":   {"arrived": true, "canceled": true, "cancelled": true},
		"arrived":    {"in_transit": true, "canceled": true, "cancelled": true},
		"in_transit": {"completed": true, "canceled": true, "cancelled": true},
	}
	if !allowed[current.Status][next] {
		return domain.Ride{}, errors.New("invalid ride status transition")
	}
	return repository.UpdateStatus(ctx, rideID, next)
}

func CalculateFare(distanceKm, durationMinutes float64) int64 {
	total := 2500 + distanceKm*100 + durationMinutes*50
	if total < 2500 {
		return 2500
	}
	return int64(total)
}

func (service *Service) DriverStats(ctx context.Context, driverID int) (domain.DriverStats, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return domain.DriverStats{}, errors.New("driver analytics persistence is unavailable")
	}
	return repository.DriverStats(ctx, driverID)
}

func (service *Service) DriverTrips(ctx context.Context, driverID int) ([]domain.Ride, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return nil, errors.New("driver trip persistence is unavailable")
	}
	return repository.DriverTrips(ctx, driverID)
}

func (service *Service) PassengerRides(ctx context.Context, passengerID int) ([]domain.Ride, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return nil, errors.New("passenger ride persistence is unavailable")
	}
	return repository.PassengerRides(ctx, passengerID)
}

func (service *Service) DriverReviews(ctx context.Context, driverID, limit, offset int) ([]domain.Review, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return nil, errors.New("driver review persistence is unavailable")
	}
	return repository.DriverReviews(ctx, driverID, limit, offset)
}

func (service *Service) CreateReview(ctx context.Context, review domain.Review) (domain.Review, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return domain.Review{}, errors.New("driver review persistence is unavailable")
	}
	if review.Rating < 1 || review.Rating > 5 {
		return domain.Review{}, errors.New("rating must be between 1 and 5")
	}
	return repository.CreateReview(ctx, review)
}

func (service *Service) OnlineDrivers(ctx context.Context) ([]domain.OnlineDriver, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return nil, errors.New("online driver persistence is unavailable")
	}
	return repository.OnlineDrivers(ctx)
}
