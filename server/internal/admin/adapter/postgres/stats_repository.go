package postgres

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
)

type DashboardStatsRepository struct{ client *ent.Client }

func NewDashboardStatsRepository(client *ent.Client) *DashboardStatsRepository {
	return &DashboardStatsRepository{client: client}
}
func (repository *DashboardStatsRepository) Stats(ctx context.Context) (domain.Stats, error) {
	users, err := repository.client.User.Query().Count(ctx)
	if err != nil {
		return domain.Stats{}, err
	}
	rides, err := repository.client.Ride.Query().Count(ctx)
	if err != nil {
		return domain.Stats{}, err
	}
	documents, err := repository.client.DriverDocument.Query().Count(ctx)
	if err != nil {
		return domain.Stats{}, err
	}
	return domain.Stats{Users: users, Rides: rides, DriverDocuments: documents}, nil
}
