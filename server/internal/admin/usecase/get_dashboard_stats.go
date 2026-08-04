package usecase

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
)

type Service struct{ repository domain.Repository }

func NewService(repository domain.Repository) *Service { return &Service{repository: repository} }
func (service *Service) DashboardStats(ctx context.Context) (domain.Stats, error) {
	return service.repository.Stats(ctx)
}
