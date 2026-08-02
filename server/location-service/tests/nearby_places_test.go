package tests

import (
	"context"
	"location-service/internal/adapter/mapbox"
	"location-service/internal/usecase"
	"testing"
)

func TestGetNearbyPlaces(t *testing.T) {
	repo := mapbox.NewMapboxAdapter(mapboxAccessToken(t))
	uc := usecase.NewLocationUseCase(repo, nil, nil)
	lat, lng := locationTestCoordinates(t)

	ctx := context.Background()
	places, err := uc.GetNearbyPois(ctx, lat, lng, 1)
	if err != nil {
		t.Fatalf("GetNearbyPois failed: %v", err)
	}

	for _, p := range places {
		if p.DistanceKm > 10.0 {
			t.Errorf("nearby result %q is %.2f km away", p.Name, p.DistanceKm)
		}
	}
}
