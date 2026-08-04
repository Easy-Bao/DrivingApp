package admin_test

import (
	"context"
	"testing"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
)
type repository struct{}
func (repository) Stats(context.Context) (domain.Stats, error) { return domain.Stats{Users: 2}, nil }
func TestDashboardStatsDelegatesToRepository(t *testing.T) { stats, err := usecase.NewService(repository{}).DashboardStats(context.Background()); if err != nil || stats.Users != 2 { t.Fatalf("stats = %#v, %v", stats, err) } }
