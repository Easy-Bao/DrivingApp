package ports

import "context"

// RouteMetrics carries provider-authoritative values into pricing and booking;
// callers must not replace them with client estimates.
type RouteMetrics struct {
	DistanceKm      float64
	DurationMinutes float64
}

// RouteProvider isolates route calculation from the mapping adapter.
type RouteProvider interface {
	CalculateRoute(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (RouteMetrics, error)
}

// RouteProviderFunc adapts a route function without introducing a concrete
// provider dependency.
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
