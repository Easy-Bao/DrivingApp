package application

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"maps"
	"slices"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	locationports "github.com/Easy-Bao/DrivingApp/server/internal/location/ports"
)

var (
	ErrEmptySearch         = errors.New("location search query is empty")
	ErrSearchTooLong       = errors.New("location search query is too long")
	ErrInvalidCoordinates  = errors.New("location coordinates are invalid")
	ErrInvalidNearbyPage   = errors.New("location page is invalid")
	ErrInvalidRouteOptions = errors.New("location route options are invalid")
	ErrInvalidMatrix       = errors.New("location matrix request is invalid")
	ErrProviderUnavailable = errors.New("location provider is unavailable")
)

const (
	_maxSearchQueryBytes   = 256
	_maxNearbyPage         = 100
	_maxMatrixDestinations = 10
)

type LocationService struct {
	provider locationports.Provider
	cache    locationports.Cache
	logger   *slog.Logger
}

type LocationServiceOption func(*LocationService)

func WithCache(cache locationports.Cache) LocationServiceOption {
	return func(service *LocationService) {
		service.cache = cache
	}
}

func NewLocationService(
	provider locationports.Provider,
	options ...LocationServiceOption,
) *LocationService {
	service := &LocationService{provider: provider, logger: slog.Default()}
	for _, option := range options {
		if option != nil {
			option(service)
		}
	}
	return service
}

func (service *LocationService) WithLogger(logger *slog.Logger) *LocationService {
	if service != nil && logger != nil {
		service.logger = logger
	}
	return service
}

func (service *LocationService) Search(
	ctx context.Context,
	query string,
	origin domain.Coordinates,
) ([]domain.Place, error) {
	query = strings.TrimSpace(query)
	if query == "" {
		return nil, ErrEmptySearch
	}
	if len(query) > _maxSearchQueryBytes {
		return nil, ErrSearchTooLong
	}
	if !origin.Valid() {
		return nil, ErrInvalidCoordinates
	}
	if service.provider == nil {
		return nil, ErrProviderUnavailable
	}
	key := fmt.Sprintf("search:%s:%.4f:%.4f", query, origin.Latitude, origin.Longitude)
	places := []domain.Place{}
	if service.cacheHit(ctx, key, &places) {
		return clonePlaces(places), nil
	}
	places, err := service.provider.Search(ctx, query, origin)
	if err != nil {
		return nil, fmt.Errorf("search locations: %w", err)
	}
	service.cacheSet(ctx, key, clonePlaces(places))
	return clonePlaces(places), nil
}

func (service *LocationService) Nearby(
	ctx context.Context,
	origin domain.Coordinates,
	page int,
) ([]domain.Place, error) {
	if page < 1 || page > _maxNearbyPage {
		return nil, ErrInvalidNearbyPage
	}
	if !origin.Valid() {
		return nil, ErrInvalidCoordinates
	}
	if service.provider == nil {
		return nil, ErrProviderUnavailable
	}
	key := fmt.Sprintf("nearby:%.4f:%.4f:%d", origin.Latitude, origin.Longitude, page)
	places := []domain.Place{}
	if service.cacheHit(ctx, key, &places) {
		return clonePlaces(places), nil
	}
	places, err := service.provider.Nearby(ctx, origin, page)
	if err != nil {
		return nil, fmt.Errorf("load nearby locations: %w", err)
	}
	service.cacheSet(ctx, key, clonePlaces(places))
	return clonePlaces(places), nil
}

func (service *LocationService) ReverseGeocode(
	ctx context.Context,
	coordinates domain.Coordinates,
) (*domain.Place, error) {
	if !coordinates.Valid() {
		return nil, ErrInvalidCoordinates
	}
	if service.provider == nil {
		return nil, ErrProviderUnavailable
	}
	key := fmt.Sprintf("reverse:%.4f:%.4f", coordinates.Latitude, coordinates.Longitude)
	var place domain.Place
	if service.cacheHit(ctx, key, &place) {
		return clonePlace(&place), nil
	}
	result, err := service.provider.ReverseGeocode(ctx, coordinates)
	if err != nil {
		return nil, fmt.Errorf("reverse geocode location: %w", err)
	}
	if result != nil {
		service.cacheSet(ctx, key, clonePlace(result))
	}
	return clonePlace(result), nil
}

func (service *LocationService) Route(
	ctx context.Context,
	origin domain.Coordinates,
	destination domain.Coordinates,
	options domain.RouteOptions,
) (*domain.Route, error) {
	if !origin.Valid() || !destination.Valid() {
		return nil, ErrInvalidCoordinates
	}
	if service.provider == nil {
		return nil, ErrProviderUnavailable
	}
	normalizedOptions, err := options.Normalize()
	if err != nil {
		return nil, fmt.Errorf("%w: %w", ErrInvalidRouteOptions, err)
	}
	result, err := service.provider.Route(
		ctx,
		origin,
		destination,
		normalizedOptions,
	)
	if err != nil {
		return nil, fmt.Errorf("calculate location route: %w", err)
	}
	return cloneRoute(result), nil
}

func (service *LocationService) Matrix(
	ctx context.Context,
	origin domain.Coordinates,
	destinations []domain.Coordinates,
) (*domain.Matrix, error) {
	invalidOrigin := !origin.Valid()
	invalidDestinationCount := len(destinations) == 0 || len(destinations) > _maxMatrixDestinations
	if invalidOrigin || invalidDestinationCount {
		return nil, ErrInvalidMatrix
	}
	if service.provider == nil {
		return nil, ErrProviderUnavailable
	}
	for _, destination := range destinations {
		if !destination.Valid() {
			return nil, ErrInvalidMatrix
		}
	}
	key := matrixCacheKey(origin, destinations)
	var matrix domain.Matrix
	if service.cacheHit(ctx, key, &matrix) {
		return cloneMatrix(&matrix), nil
	}
	result, err := service.provider.Matrix(ctx, origin, slices.Clone(destinations))
	if err != nil {
		return nil, fmt.Errorf("calculate location matrix: %w", err)
	}
	service.cacheSet(ctx, key, cloneMatrix(result))
	return cloneMatrix(result), nil
}

func clonePlaces(values []domain.Place) []domain.Place {
	if values == nil {
		return nil
	}
	cloned := make([]domain.Place, len(values))
	for index, value := range values {
		cloned[index] = value
		cloned[index].Context = maps.Clone(value.Context)
	}
	return cloned
}

func clonePlace(value *domain.Place) *domain.Place {
	if value == nil {
		return nil
	}
	cloned := *value
	cloned.Context = maps.Clone(value.Context)
	return &cloned
}

func cloneRoute(value *domain.Route) *domain.Route {
	if value == nil {
		return nil
	}
	cloned := *value
	if value.Polyline != nil {
		cloned.Polyline = make([][]float64, len(value.Polyline))
		for index, line := range value.Polyline {
			cloned.Polyline[index] = slices.Clone(line)
		}
	}
	return &cloned
}

func cloneMatrix(value *domain.Matrix) *domain.Matrix {
	if value == nil {
		return nil
	}
	cloned := *value
	cloned.DistancesKm = slices.Clone(value.DistancesKm)
	cloned.DurationsMin = slices.Clone(value.DurationsMin)
	return &cloned
}

func (service *LocationService) cacheHit(ctx context.Context, key string, target any) bool {
	if service.cache == nil {
		return false
	}
	if err := service.cache.Get(ctx, key, target); err != nil {
		if !errors.Is(err, locationports.ErrCacheMiss) {
			service.log().DebugContext(ctx, "load location cache entry failed", "error", err, "operation", "get")
		}
		return false
	}
	return true
}

func (service *LocationService) cacheSet(ctx context.Context, key string, value any) {
	if service.cache == nil {
		return
	}
	if err := service.cache.Set(ctx, key, value); err != nil {
		service.log().DebugContext(ctx, "store location cache entry failed", "error", err, "operation", "set")
	}
}

func (service *LocationService) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}

func matrixCacheKey(origin domain.Coordinates, destinations []domain.Coordinates) string {
	var builder strings.Builder
	fmt.Fprintf(&builder, "matrix:%.4f:%.4f", origin.Latitude, origin.Longitude)
	for _, destination := range destinations {
		fmt.Fprintf(&builder, ":%.4f:%.4f", destination.Latitude, destination.Longitude)
	}
	return builder.String()
}
