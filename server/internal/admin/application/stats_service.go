package application

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/ports"
)

// StatsService serves administrative read models without coupling the use case
// to a storage technology.
type StatsService struct{ reader ports.StatsReader }

func NewStatsService(reader ports.StatsReader) *StatsService {
	return &StatsService{reader: reader}
}

func (service *StatsService) Stats(ctx context.Context) (domain.Stats, error) {
	return service.reader.Stats(ctx)
}
