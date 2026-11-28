package mapbox

import (
	"context"
	"fmt"
	"math"
	"net/url"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/places/domain"
)

func (provider *RoutingProvider) Route(
	ctx context.Context,
	origin domain.Coordinates,
	destination domain.Coordinates,
	options domain.RouteOptions,
) (*domain.Route, error) {
	if err := provider.validate(); err != nil {
		return nil, err
	}
	if !origin.Valid() || !destination.Valid() {
		return nil, fmt.Errorf("invalid route coordinates")
	}
	normalizedOptions, err := options.Normalize()
	if err != nil {
		return nil, fmt.Errorf("normalize route options: %w", err)
	}
	cacheKey := routeCacheKey(origin, destination, normalizedOptions)
	if routes, ok := provider.cachedRoutes(cacheKey); ok {
		return routeFromMapbox(
			origin,
			destination,
			normalizedOptions,
			routes,
		), nil
	}
	coordinates := strings.Join([]string{
		coordinate(origin.Longitude) + "," + coordinate(origin.Latitude),
		coordinate(destination.Longitude) + "," + coordinate(destination.Latitude),
	}, ";")
	queryParams := url.Values{
		"access_token": {provider.token},
		"alternatives": {"true"},
		"overview":     {"full"},
		"geometries":   {"geojson"},
	}
	if len(normalizedOptions.ExcludePoints) > 0 {
		excludedPoints := make([]string, 0, len(normalizedOptions.ExcludePoints))
		for _, point := range normalizedOptions.ExcludePoints {
			pointValue := fmt.Sprintf(
				"point(%s %s)",
				coordinate(point.Longitude),
				coordinate(point.Latitude),
			)
			excludedPoints = append(excludedPoints, pointValue)
		}
		queryParams.Set("exclude", strings.Join(excludedPoints, ","))
	}
	var response directionsResponse
	endpoint := _directionsURL + "/" + string(normalizedOptions.Profile) + "/" + coordinates + "?" + queryParams.Encode()
	if err := provider.getJSON(ctx, endpoint, &response); err != nil {
		return nil, fmt.Errorf("calculate route: %w", err)
	}
	if len(response.Routes) == 0 {
		return nil, fmt.Errorf("mapbox returned no route")
	}
	provider.storeRoutes(cacheKey, response.Routes)
	return routeFromMapbox(origin, destination, normalizedOptions, response.Routes), nil
}

func routeCacheKey(origin, destination domain.Coordinates, options domain.RouteOptions) string {
	var buffer [256]byte
	key := appendRouteCoordinatePair(buffer[:0], origin)
	key = appendRouteCoordinatePair(append(key, ';'), destination)
	key = append(append(key, '|'), options.Profile...)
	for _, point := range options.ExcludePoints {
		key = appendRouteCoordinatePair(append(key, '|'), point)
	}
	return string(key)
}

func appendRouteCoordinatePair(key []byte, point domain.Coordinates) []byte {
	key = strconv.AppendFloat(key, point.Longitude, 'f', _coordinatePrecision, 64)
	return strconv.AppendFloat(append(key, ','), point.Latitude, 'f', _coordinatePrecision, 64)
}

func routeFromMapbox(
	origin, destination domain.Coordinates,
	options domain.RouteOptions,
	routes []cachedRoute,
) *domain.Route {
	selected := selectRoute(routes, options.Preference)
	return &domain.Route{
		Origin:      origin,
		Destination: destination,
		Preference:  string(options.Preference),
		Profile:     string(options.Profile),
		DistanceKm:  selected.Distance / 1000,
		DurationMin: selected.Duration / 60,
		Polyline:    slices.Clone(selected.Geometry.Coordinates),
	}
}

func (provider *RoutingProvider) cachedRoutes(key string) ([]cachedRoute, bool) {
	provider.routeCacheMu.Lock()
	defer provider.routeCacheMu.Unlock()

	entry, ok := provider.routeCache[key]
	if !ok {
		return nil, false
	}
	if time.Since(entry.createdAt) >= _routeCacheTTL {
		delete(provider.routeCache, key)
		return nil, false
	}
	return cloneCachedRoutes(entry.routes), true
}

func (provider *RoutingProvider) storeRoutes(key string, routes []cachedRoute) {
	if len(routes) == 0 {
		return
	}
	provider.routeCacheMu.Lock()
	defer provider.routeCacheMu.Unlock()

	if provider.routeCache == nil {
		provider.routeCache = make(map[string]routeCacheEntry)
	}
	if _, exists := provider.routeCache[key]; !exists && len(provider.routeCache) >= _routeCacheMaxEntries {
		oldestKey := ""
		var oldest time.Time
		for candidateKey, candidate := range provider.routeCache {
			if oldestKey == "" || candidate.createdAt.Before(oldest) {
				oldestKey = candidateKey
				oldest = candidate.createdAt
			}
		}
		delete(provider.routeCache, oldestKey)
	}
	provider.routeCache[key] = routeCacheEntry{
		routes:    cloneCachedRoutes(routes),
		createdAt: time.Now(),
	}
}

func cloneCachedRoutes(routes []cachedRoute) []cachedRoute {
	clones := slices.Clone(routes)
	for index := range clones {
		clones[index].Geometry.Coordinates = make([][]float64, len(routes[index].Geometry.Coordinates))
		for pointIndex, point := range routes[index].Geometry.Coordinates {
			clones[index].Geometry.Coordinates[pointIndex] = slices.Clone(point)
		}
	}
	return clones
}

func (provider *RoutingProvider) Matrix(
	ctx context.Context,
	origin domain.Coordinates,
	destinations []domain.Coordinates,
) (*domain.Matrix, error) {
	if err := provider.validate(); err != nil {
		return nil, err
	}
	invalidOrigin := !origin.Valid()
	invalidDestinationCount := len(destinations) == 0 || len(destinations) > 10
	if invalidOrigin || invalidDestinationCount {
		return nil, fmt.Errorf("invalid travel matrix coordinates")
	}
	for _, destination := range destinations {
		if !destination.Valid() {
			return nil, fmt.Errorf("invalid travel matrix coordinates")
		}
	}
	if len(destinations) == 1 {
		route, err := provider.Route(
			ctx,
			origin,
			destinations[0],
			domain.RouteOptions{},
		)
		if err != nil {
			return nil, fmt.Errorf("calculate matrix route: %w", err)
		}
		return &domain.Matrix{
			DistancesKm:  []float64{route.DistanceKm},
			DurationsMin: []float64{route.DurationMin},
		}, nil
	}

	coordinates := make([]string, 0, len(destinations)+1)
	coordinates = append(coordinates, coordinate(origin.Longitude)+","+coordinate(origin.Latitude))
	destinationIndexes := make([]string, 0, len(destinations))
	for index, destination := range destinations {
		coordinates = append(coordinates, coordinate(destination.Longitude)+","+coordinate(destination.Latitude))
		destinationIndexes = append(destinationIndexes, strconv.Itoa(index+1))
	}
	queryParams := url.Values{
		"access_token": {provider.token},
		"annotations":  {"distance,duration"},
		"sources":      {"0"},
		"destinations": {strings.Join(destinationIndexes, ";")},
	}
	var response matrixResponse
	endpoint := _matrixURL + "/" + strings.Join(coordinates, ";") + "?" + queryParams.Encode()
	if err := provider.getJSON(ctx, endpoint, &response); err != nil {
		return nil, fmt.Errorf("calculate travel matrix: %w", err)
	}
	invalidDistanceRows := len(response.Distances) != 1
	invalidDurationRows := len(response.Durations) != 1
	invalidResponseCode := response.Code != "Ok"
	if invalidResponseCode || invalidDistanceRows || invalidDurationRows {
		return nil, fmt.Errorf("location provider returned an invalid travel matrix")
	}
	invalidDistanceCount := len(response.Distances[0]) != len(destinations)
	invalidDurationCount := len(response.Durations[0]) != len(destinations)
	if invalidDistanceCount || invalidDurationCount {
		return nil, fmt.Errorf("location provider returned an invalid travel matrix")
	}
	matrix := &domain.Matrix{
		DistancesKm:  make([]float64, len(destinations)),
		DurationsMin: make([]float64, len(destinations)),
	}
	for index := range destinations {
		distance := response.Distances[0][index]
		duration := response.Durations[0][index]
		invalidDistance := distance == nil ||
			math.IsNaN(*distance) || math.IsInf(*distance, 0) || *distance < 0
		invalidDuration := duration == nil ||
			math.IsNaN(*duration) || math.IsInf(*duration, 0) || *duration < 0
		if invalidDistance || invalidDuration {
			return nil, fmt.Errorf("location provider could not route every travel matrix destination")
		}
		matrix.DistancesKm[index] = *distance / 1000
		matrix.DurationsMin[index] = *duration / 60
	}
	return matrix, nil
}

func selectRoute(routes []cachedRoute, preference domain.RoutePreference) cachedRoute {
	fastest := routes[0]
	shortest := routes[0]
	for _, candidate := range routes[1:] {
		if candidate.Duration < fastest.Duration {
			fastest = candidate
		}
		if candidate.Distance < shortest.Distance {
			shortest = candidate
		}
	}

	if preference == domain.RoutePreferenceShortest {
		// Mapbox alternatives are close-in-time alternatives, not a global
		// shortest-path search. Keep the primary driveable route unless the
		// alternative provides a meaningful distance reduction.
		const meaningfulDistanceReduction = 0.9
		if shortest.Distance < fastest.Distance*meaningfulDistanceReduction {
			return shortest
		}
	}
	return fastest
}
