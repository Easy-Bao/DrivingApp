package application

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
)

type StatsService struct{ repository domain.Repository }

func NewStatsService(repository domain.Repository) *StatsService {
	return &StatsService{repository: repository}
}
func (service *StatsService) Stats(ctx context.Context) (domain.Stats, error) {
	return service.repository.Stats(ctx)
}
