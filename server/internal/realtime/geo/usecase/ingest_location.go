package usecase

import (
	"context"
	"errors"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
)

type Service struct{ repository domain.Repository }

func NewService(repository domain.Repository) *Service { return &Service{repository: repository} }
func (service *Service) Ingest(ctx context.Context, point domain.DriverPoint) error {
	return service.repository.Upsert(ctx, point)
}
func (service *Service) Nearby(ctx context.Context, latitude, longitude, radiusKm float64) ([]domain.DriverPoint, error) {
	return service.repository.Nearby(ctx, latitude, longitude, radiusKm)
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
	return repository.UpsertPassenger(ctx, rideID, point)
}

func (service *Service) GetPassenger(ctx context.Context, rideID string) (domain.DriverPoint, error) {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return domain.DriverPoint{}, errors.New("passenger location lookup is unavailable")
	}
	return repository.GetPassenger(ctx, rideID)
}
