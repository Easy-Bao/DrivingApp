package mapbox

import (
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

var benchmarkRouteKey string

func BenchmarkRouteCacheKey(b *testing.B) {
	origin := domain.Coordinates{Latitude: 7.8282, Longitude: 123.4361}
	destination := domain.Coordinates{Latitude: 7.9000, Longitude: 123.5000}
	options := domain.RouteOptions{
		Profile: domain.RouteProfileDrivingTraffic,
		ExcludePoints: []domain.Coordinates{
			{Latitude: 7.8300, Longitude: 123.4400},
			{Latitude: 7.8400, Longitude: 123.4500},
			{Latitude: 7.8500, Longitude: 123.4600},
			{Latitude: 7.8600, Longitude: 123.4700},
		},
	}

	b.ReportAllocs()
	for b.Loop() {
		benchmarkRouteKey = routeCacheKey(origin, destination, options)
	}
}
