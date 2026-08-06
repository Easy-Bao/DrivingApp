package usecase

import (
	"context"
	"errors"
	"math"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
)

type Service struct{ repository domain.Repository }

func NewService(repository domain.Repository) *Service { return &Service{repository: repository} }
func (service *Service) Ingest(ctx context.Context, point domain.DriverPoint) error {
	if !validCoordinates(point.Latitude, point.Longitude) || point.DriverID == "" {
		return errors.New("invalid driver location")
	}
	return service.repository.Upsert(ctx, point)
}
func (service *Service) Nearby(ctx context.Context, latitude, longitude, radiusKm float64) ([]domain.DriverPoint, error) {
	if !validCoordinates(latitude, longitude) || math.IsNaN(radiusKm) || math.IsInf(radiusKm, 0) || radiusKm <= 0 || radiusKm > 50 {
		return nil, errors.New("invalid nearby location")
	}
	return service.repository.Nearby(ctx, latitude, longitude, radiusKm)
}

func (service *Service) Remove(ctx context.Context, driverID string) error {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return errors.New("driver location removal is unavailable")
	}
	if driverID == "" {
		return errors.New("driver id is required")
	}
	return repository.Remove(ctx, driverID)
}

func (service *Service) Get(ctx context.Context, driverID string) (domain.DriverPoint, error) {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return domain.DriverPoint{}, errors.New("location lookup is unavailable")
	}
	return repository.Get(ctx, driverID)
}

func (service *Service) UpdatePassenger(ctx context.Context, rideID string, point domain.DriverPoint) error {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return errors.New("passenger location persistence is unavailable")
	}
	if rideID == "" || !validCoordinates(point.Latitude, point.Longitude) {
		return errors.New("invalid passenger location")
	}
	return repository.UpsertPassenger(ctx, rideID, point)
}

func (service *Service) GetPassenger(ctx context.Context, rideID string) (domain.DriverPoint, error) {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return domain.DriverPoint{}, errors.New("passenger location lookup is unavailable")
	}
	return repository.GetPassenger(ctx, rideID)
}

func validCoordinates(latitude, longitude float64) bool {
	return !math.IsNaN(latitude) && !math.IsInf(latitude, 0) && latitude >= -90 && latitude <= 90 &&
		!math.IsNaN(longitude) && !math.IsInf(longitude, 0) && longitude >= -180 && longitude <= 180
}
