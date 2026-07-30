package tests

import (
	"context"
	"location-service/internal/adapter/postgres"
	"location-service/internal/usecase"
	"testing"
)

func TestSearchPlaces(t *testing.T) {
	repo := postgres.NewPostgresAdapter("")
	uc := usecase.NewLocationUseCase(repo, nil, nil)

	ctx := context.Background()
	results, err := uc.SearchPlaces(ctx, "Springland", 7.8250, 123.4300)
	if err != nil {
		t.Fatalf("SearchPlaces failed: %v", err)
	}

	if len(results) == 0 {
		t.Fatal("Expected search results for 'Springland', got empty list")
	}

	if results[0].Name != "Springland Resort" {
		t.Errorf("Expected first result to be Springland Resort, got: %s", results[0].Name)
	}
}
