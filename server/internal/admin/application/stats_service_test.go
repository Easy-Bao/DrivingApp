package application_test

import (
	"context"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
)

type statsReader struct{}

func (statsReader) Stats(context.Context) (domain.Stats, error) {
	return domain.Stats{Users: 2}, nil
}

func TestStatsDelegatesToReader(t *testing.T) {
	stats, err := application.NewStatsService(statsReader{}).Stats(context.Background())
	if err != nil || stats.Users != 2 {
		t.Fatalf("stats = %#v, %v", stats, err)
	}
}
