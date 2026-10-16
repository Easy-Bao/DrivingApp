package app_test

import (
	"context"
	"testing"

	adminapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/domain"
)

type statsReader struct{}

func (statsReader) Stats(context.Context) (domain.Stats, error) {
	return domain.Stats{Users: 2}, nil
}

func TestStatsDelegatesToReader(t *testing.T) {
	stats, err := adminapp.NewStatsService(statsReader{}).Stats(context.Background())
	if err != nil || stats.Users != 2 {
		t.Fatalf("stats = %#v, %v", stats, err)
	}
}
