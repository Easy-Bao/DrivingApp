package admin_test

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"testing"
)

type repository struct{}

func (repository) Stats(context.Context) (domain.Stats, error) { return domain.Stats{Users: 2}, nil }
func TestDashboardStatsDelegatesToRepository(t *testing.T) {
	stats, err := usecase.NewDashboardStatsService(repository{}).DashboardStats(context.Background())
	if err != nil || stats.Users != 2 {
		t.Fatalf("stats = %#v, %v", stats, err)
	}
}
