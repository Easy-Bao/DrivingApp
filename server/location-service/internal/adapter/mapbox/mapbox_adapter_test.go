package mapbox

import "testing"

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

func routeFixture(distance, duration float64) mapboxRoute {
	route := mapboxRoute{Distance: distance, Duration: duration}
	route.Geometry.Coordinates = [][]float64{{123.43, 7.82}, {123.44, 7.83}}
	return route
}
