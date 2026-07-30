package tests

import (
	"context"
	"location-service/internal/adapter/postgres"
	"location-service/internal/usecase"
	"testing"
)

func TestReverseGeocode(t *testing.T) {
	repo := postgres.NewPostgresAdapter("")
	uc := usecase.NewLocationUseCase(repo, nil, nil)

	ctx := context.Background()
	place, err := uc.ReverseGeocode(ctx, 7.8242, 123.4350)
	if err != nil {
		t.Fatalf("ReverseGeocode failed: %v", err)
	}

	if place == nil {
		t.Fatal("Expected place to be non-nil")
	}

	if place.Name == "" || place.Name == "Unknown location" {
		t.Errorf("Expected valid place name, got: %s", place.Name)
	}

	if place.Name != "Springland Resort" {
		t.Errorf("Expected Springland Resort, got: %s", place.Name)
	}
}
