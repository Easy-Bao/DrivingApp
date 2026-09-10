package application

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/ports"
)

// StatsService serves administrative read models without coupling the use case
// to a storage technology.
type StatsService struct{ repository ports.StatsReader }

func NewStatsService(repository ports.StatsReader) *StatsService {
	return &StatsService{repository: repository}
}

func (service *StatsService) Stats(ctx context.Context) (domain.Stats, error) {
	return service.repository.Stats(ctx)
}
