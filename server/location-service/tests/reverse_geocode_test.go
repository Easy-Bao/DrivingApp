package tests

import (
	"context"
	"location-service/internal/adapter/mapbox"
	"location-service/internal/usecase"
	"testing"
)

func TestReverseGeocode(t *testing.T) {
	repo := mapbox.NewMapboxAdapter(mapboxAccessToken(t))
	uc := usecase.NewLocationUseCase(repo, nil, nil)
	lat, lng := locationTestCoordinates(t)

	ctx := context.Background()
	place, err := uc.ReverseGeocode(ctx, lat, lng)
	if err != nil {
		t.Fatalf("ReverseGeocode failed: %v", err)
	}

	if place == nil {
		t.Fatal("Expected place to be non-nil")
	}

	if place.Name == "" {
		t.Errorf("Expected valid place name, got: %s", place.Name)
	}
}
