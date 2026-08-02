package tests

import (
	"context"
	"location-service/internal/adapter/mapbox"
	"location-service/internal/usecase"
	"os"
	"testing"
)

func TestSearchPlaces(t *testing.T) {
	query, ok := os.LookupEnv("LOCATION_TEST_QUERY")
	if !ok || query == "" {
		t.Skip("LOCATION_TEST_QUERY is required for database-backed location tests")
	}
	repo := mapbox.NewMapboxAdapter(mapboxAccessToken(t))
	uc := usecase.NewLocationUseCase(repo, nil, nil)
	lat, lng := locationTestCoordinates(t)

	ctx := context.Background()
	results, err := uc.SearchPlaces(ctx, query, lat, lng)
	if err != nil {
		t.Fatalf("SearchPlaces failed: %v", err)
	}

	if len(results) == 0 {
		t.Fatalf("Expected search results for %q, got empty list", query)
	}
}
