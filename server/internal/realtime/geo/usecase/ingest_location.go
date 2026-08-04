package usecase

import (
	"context"
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
