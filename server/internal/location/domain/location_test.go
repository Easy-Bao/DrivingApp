package domain

import (
	"math"
	"testing"
)

func TestCoordinatesValid(t *testing.T) {
	tests := []struct {
		name        string
		coordinates Coordinates
		want        bool
	}{
		{
			name:        "valid boundaries",
			coordinates: Coordinates{Latitude: -90, Longitude: 180},
			want:        true,
		},
		{
			name:        "latitude outside range",
			coordinates: Coordinates{Latitude: 90.1, Longitude: 0},
		},
		{
			name:        "longitude outside range",
			coordinates: Coordinates{Latitude: 0, Longitude: -180.1},
		},
		{
			name:        "not a number",
			coordinates: Coordinates{Latitude: math.NaN(), Longitude: 0},
		},
		{
			name:        "infinite",
			coordinates: Coordinates{Latitude: 0, Longitude: math.Inf(1)},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := test.coordinates.Valid(); got != test.want {
				t.Fatalf("Coordinates.Valid() = %t, want %t", got, test.want)
			}
		})
	}
}

func TestRouteOptionsNormalizeCopiesExcludedPoints(t *testing.T) {
	points := []Coordinates{{Latitude: 1, Longitude: 2}}
	options, err := (RouteOptions{ExcludePoints: points}).Normalize()
	if err != nil {
		t.Fatalf("Normalize() error = %v", err)
	}

	points[0].Latitude = 99
	if options.ExcludePoints[0].Latitude != 1 {
		t.Fatalf("normalized options changed with caller input: %#v", options.ExcludePoints)
	}
}
