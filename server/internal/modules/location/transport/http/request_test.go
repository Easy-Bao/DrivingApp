package http

import (
	"encoding/json"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
)

func TestRouteRequestMapsCoordinatesAndExclusionPoints(t *testing.T) {
	request := RouteRequest{
		Origin:        Coordinate{Latitude: 6.7, Longitude: 122.1},
		Destination:   Coordinate{Latitude: 7.8, Longitude: 123.4},
		Preference:    domain.RoutePreferenceShortest,
		Profile:       domain.RouteProfileDrivingTraffic,
		ExcludePoints: []Coordinate{{Latitude: 7, Longitude: 123}},
	}
	options, err := request.Options()
	if err != nil {
		t.Fatalf("route options: %v", err)
	}
	if request.Origin.ToDomain() != (domain.Coordinates{Latitude: 6.7, Longitude: 122.1}) ||
		request.Destination.ToDomain() != (domain.Coordinates{Latitude: 7.8, Longitude: 123.4}) {
		t.Fatalf("route coordinates = %#v/%#v", request.Origin.ToDomain(), request.Destination.ToDomain())
	}
	if options.Preference != domain.RoutePreferenceShortest || options.Profile != domain.RouteProfileDrivingTraffic ||
		len(options.ExcludePoints) != 1 || options.ExcludePoints[0] != (domain.Coordinates{Latitude: 7, Longitude: 123}) {
		t.Fatalf("route options = %#v", options)
	}
}

func TestMatrixRequestMapsCoordinates(t *testing.T) {
	request := MatrixRequest{
		Origin:       Coordinate{Latitude: 6.7, Longitude: 122.1},
		Destinations: []Coordinate{{Latitude: 7.8, Longitude: 123.4}},
	}
	if request.DomainOrigin() != (domain.Coordinates{Latitude: 6.7, Longitude: 122.1}) {
		t.Fatalf("matrix origin = %#v", request.DomainOrigin())
	}
	wantDestinations := []domain.Coordinates{{Latitude: 7.8, Longitude: 123.4}}
	if got := request.DomainDestinations(); len(got) != len(wantDestinations) || got[0] != wantDestinations[0] {
		t.Fatalf("matrix destinations = %#v, want %#v", got, wantDestinations)
	}
}

func TestCoordinateKeepsLatLngRequestNames(t *testing.T) {
	encoded, err := json.Marshal(Coordinate{Latitude: 6.7, Longitude: 122.1})
	if err != nil {
		t.Fatalf("marshal coordinate: %v", err)
	}
	if string(encoded) != `{"lat":6.7,"lng":122.1}` {
		t.Fatalf("coordinate = %s", encoded)
	}
}
