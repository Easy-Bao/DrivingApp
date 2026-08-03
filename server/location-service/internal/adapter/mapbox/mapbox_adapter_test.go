package mapbox

import (
	"location-service/internal/domain"
	"testing"
)

func TestCanonicalSearchQueryExpandsShortAcronyms(t *testing.T) {
	tests := []struct {
		name  string
		query string
		want  string
	}{
		{name: "compact acronym", query: "jh", want: "j.h"},
		{name: "uppercase acronym", query: "JH", want: "J.H"},
		{name: "punctuated acronym", query: "J.H", want: "J.H"},
		{name: "normal word", query: "hotel", want: "hotel"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := canonicalSearchQuery(test.query); got != test.want {
				t.Fatalf("canonicalSearchQuery(%q) = %q, want %q", test.query, got, test.want)
			}
		})
	}
}

func TestSelectBestRouteSkipsInvalidAndChoosesShortestDistance(t *testing.T) {
	invalid := mapboxRoute{}
	longer := routeFixture(1200, 300)
	shorter := routeFixture(800, 420)

	selected, ok := selectBestRoute([]mapboxRoute{invalid, longer, shorter})
	if !ok {
		t.Fatal("expected a valid route")
	}
	if selected.Distance != shorter.Distance {
		t.Fatalf("expected shortest route distance %.0f, got %.0f", shorter.Distance, selected.Distance)
	}
}

func TestSelectBestRouteUsesDurationAsTieBreaker(t *testing.T) {
	selected, ok := selectBestRoute([]mapboxRoute{
		routeFixture(800, 420),
		routeFixture(800, 360),
	})
	if !ok {
		t.Fatal("expected a valid route")
	}
	if selected.Duration != 360 {
		t.Fatalf("expected fastest equal-distance route, got %.0f seconds", selected.Duration)
	}
}

func TestSelectBestReversePlacePrefersNearbySpecificFeatures(t *testing.T) {
	places := []domain.Place{
		{Name: "Pagadian City", Category: "place", DistanceKm: 0.1},
		{Name: "Bay Plaza Hotel", Category: "poi", DistanceKm: 0.2},
		{Name: "J.P. Rizal Avenue", Category: "street", DistanceKm: 0.05},
	}

	selected := selectBestReversePlace(places)
	if selected.Name != "Bay Plaza Hotel" {
		t.Fatalf("expected nearest POI, got %q", selected.Name)
	}
}

func routeFixture(distance, duration float64) mapboxRoute {
	route := mapboxRoute{Distance: distance, Duration: duration}
	route.Geometry.Coordinates = [][]float64{{123.43, 7.82}, {123.44, 7.83}}
	return route
}
