package app

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/domain"
)

// StatsService serves administrative read models without coupling the use case
// to a storage technology.
type StatsService struct{ reader StatsReader }

func NewStatsService(reader StatsReader) *StatsService {
	return &StatsService{reader: reader}
}

func (service *StatsService) Stats(ctx context.Context) (domain.Stats, error) {
	return service.reader.Stats(ctx)
}
