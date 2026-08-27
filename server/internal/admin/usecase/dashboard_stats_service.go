package usecase

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
)

type DashboardStatsService struct{ repository domain.Repository }

func NewDashboardStatsService(repository domain.Repository) *DashboardStatsService {
	return &DashboardStatsService{repository: repository}
}
func (service *DashboardStatsService) DashboardStats(ctx context.Context) (domain.Stats, error) {
	return service.repository.Stats(ctx)
}
