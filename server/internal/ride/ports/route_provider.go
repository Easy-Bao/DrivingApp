package ports

import "context"

// RouteMetrics is the authoritative distance and duration used by ride
// pricing and booking decisions.
type RouteMetrics struct {
	DistanceKm      float64
	DurationMinutes float64
}

// RouteProvider calculates a route using the configured mapping provider.
type RouteProvider interface {
	CalculateRoute(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (RouteMetrics, error)
}

// RouteProviderFunc adapts a function to RouteProvider.
type RouteProviderFunc func(context.Context, float64, float64, float64, float64) (RouteMetrics, error)

func (provider RouteProviderFunc) CalculateRoute(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (RouteMetrics, error) {
	return provider(ctx, originLat, originLng, destinationLat, destinationLng)
}

// RouteResolver applies the ride application's validation and fallback policy
// around a route provider.
type RouteResolver func(
	ctx context.Context,
	pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, distanceKm, durationMinutes float64,
) (RouteMetrics, error)
