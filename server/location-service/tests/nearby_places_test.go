package tests

import (
	"context"
	"location-service/internal/adapter/postgres"
	"location-service/internal/usecase"
	"testing"
)

func TestGetNearbyPlaces(t *testing.T) {
	repo := postgres.NewPostgresAdapter("")
	uc := usecase.NewLocationUseCase(repo, nil, nil)

	ctx := context.Background()
	places, err := uc.GetNearbyPois(ctx, 7.8250, 123.4300, 1)
	if err != nil {
		t.Fatalf("GetNearbyPois failed: %v", err)
	}

	if len(places) == 0 {
		t.Fatal("Expected nearby places to be found, got 0")
	}

	foundSpringland := false
	for _, p := range places {
		if p.Name == "Springland Resort" {
			foundSpringland = true
			break
		}
	}

	if !foundSpringland {
		t.Errorf("Expected Springland Resort in nearby places list")
	}
}
