package usecase

import (
	"location-service/internal/domain"
	"testing"
)

func TestFilterAndPageNearbyPlaces(t *testing.T) {
	places := []domain.Place{
		{Name: "Five", DistanceKm: 5},
		{Name: "Ten", DistanceKm: 10},
		{Name: "Outside", DistanceKm: 10.01},
		{Name: "One", DistanceKm: 1},
	}

	pageOne := filterAndPageNearbyPlaces(places, 1)
	if len(pageOne) != 3 {
		t.Fatalf("expected three places within 10 km, got %d", len(pageOne))
	}
	if pageOne[0].Name != "One" || pageOne[1].Name != "Five" || pageOne[2].Name != "Ten" {
		t.Fatalf("expected results sorted by distance, got %#v", pageOne)
	}

	pageTwo := filterAndPageNearbyPlaces(places, 2)
	if len(pageTwo) != 0 {
		t.Fatalf("expected no second page for three results, got %d", len(pageTwo))
	}
}

func TestFilterAndPageNearbyPlacesUsesTenItemPages(t *testing.T) {
	places := make([]domain.Place, 25)
	for index := range places {
		places[index] = domain.Place{
			Name:       "Place",
			DistanceKm: float64(index),
		}
	}

	pageOne := filterAndPageNearbyPlaces(places, 1)
	pageTwo := filterAndPageNearbyPlaces(places, 2)

	if len(pageOne) != nearbyPageSize || len(pageTwo) != 1 {
		t.Fatalf("expected 10 results on page one and one on page two, got %d and %d", len(pageOne), len(pageTwo))
	}
	if pageTwo[0].DistanceKm != 10 {
		t.Fatalf("expected page two to start at distance 10 km, got %.2f", pageTwo[0].DistanceKm)
	}
}
