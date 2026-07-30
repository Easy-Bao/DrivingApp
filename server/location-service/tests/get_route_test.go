package tests

import (
	"context"
	"location-service/internal/adapter/postgres"
	"location-service/internal/usecase"
	"testing"
)

func TestGetRoute(t *testing.T) {
	repo := postgres.NewPostgresAdapter("")
	uc := usecase.NewLocationUseCase(repo, nil, nil)

	ctx := context.Background()
	route, err := uc.GetRoute(ctx, 7.8242, 123.4350, 7.8320, 123.4360)
	if err != nil {
		t.Fatalf("GetRoute failed: %v", err)
	}

	if route == nil {
		t.Fatal("Expected route to be non-nil")
	}

	if route.DistanceKm <= 0 {
		t.Errorf("Expected DistanceKm > 0, got: %f", route.DistanceKm)
	}

	if len(route.Waypoints) == 0 {
		t.Errorf("Expected waypoints in route, got empty")
	}
}
