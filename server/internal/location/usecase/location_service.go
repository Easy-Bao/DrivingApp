package usecase

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

var (
	ErrEmptySearch         = errors.New("location search query is empty")
	ErrSearchTooLong       = errors.New("location search query is too long")
	ErrInvalidCoordinates  = errors.New("location coordinates are invalid")
	ErrInvalidNearbyPage   = errors.New("location page is invalid")
	ErrInvalidRouteOptions = errors.New("location route options are invalid")
	ErrInvalidMatrix       = errors.New("location matrix request is invalid")
)

const (
	maxSearchQueryBytes   = 256
	maxNearbyPage         = 100
	maxMatrixDestinations = 10
)

type LocationService struct {
	provider domain.Provider
	cache    domain.Cache
	logger   *slog.Logger
}

func NewLocationService(provider domain.Provider) *LocationService {
	return NewLocationServiceWithCache(provider, nil)
}

func NewLocationServiceWithCache(provider domain.Provider, cache domain.Cache) *LocationService {
	return &LocationService{provider: provider, cache: cache, logger: slog.Default()}
}

func (service *LocationService) WithLogger(logger *slog.Logger) *LocationService {
	if logger != nil {
		service.logger = logger
	}
	return service
}

func (service *LocationService) Search(ctx context.Context, query string, origin domain.Coordinates) ([]domain.Place, error) {
	query = strings.TrimSpace(query)
	if query == "" {
		return nil, ErrEmptySearch
	}
	if len(query) > maxSearchQueryBytes {
		return nil, ErrSearchTooLong
	}
	if !origin.Valid() {
		return nil, ErrInvalidCoordinates
	}
	key := fmt.Sprintf("search:%s:%.4f:%.4f", query, origin.Latitude, origin.Longitude)
	var places []domain.Place
	if service.cache != nil && service.cache.Get(ctx, key, &places) == nil {
		return places, nil
	}
	places, err := service.provider.Search(ctx, query, origin)
	if err == nil {
		service.cacheSet(ctx, key, places)
	}
	return places, err
}

func (service *LocationService) Nearby(ctx context.Context, origin domain.Coordinates, page int) ([]domain.Place, error) {
	if page < 1 || page > maxNearbyPage {
		return nil, ErrInvalidNearbyPage
	}
	if !origin.Valid() {
		return nil, ErrInvalidCoordinates
	}
	key := fmt.Sprintf("nearby:%.4f:%.4f:%d", origin.Latitude, origin.Longitude, page)
	var places []domain.Place
	if service.cache != nil && service.cache.Get(ctx, key, &places) == nil {
		return places, nil
	}
	places, err := service.provider.Nearby(ctx, origin, page)
	if err == nil {
		service.cacheSet(ctx, key, places)
	}
	return places, err
}

func (service *LocationService) ReverseGeocode(ctx context.Context, coordinates domain.Coordinates) (*domain.Place, error) {
	if !coordinates.Valid() {
		return nil, ErrInvalidCoordinates
	}
	key := fmt.Sprintf("reverse:%.4f:%.4f", coordinates.Latitude, coordinates.Longitude)
	var place domain.Place
	if service.cache != nil && service.cache.Get(ctx, key, &place) == nil {
		return &place, nil
	}
	result, err := service.provider.ReverseGeocode(ctx, coordinates)
	if err != nil {
		return nil, err
	}
	if result != nil {
		service.cacheSet(ctx, key, result)
	}
	return result, nil
}

func (service *LocationService) Route(ctx context.Context, origin, destination domain.Coordinates, options domain.RouteOptions) (*domain.Route, error) {
	if !origin.Valid() || !destination.Valid() {
		return nil, ErrInvalidCoordinates
	}
	normalizedOptions, err := options.Normalize()
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidRouteOptions, err)
	}
	return service.provider.Route(ctx, origin, destination, normalizedOptions)
}

func (service *LocationService) Matrix(ctx context.Context, origin domain.Coordinates, destinations []domain.Coordinates) (*domain.Matrix, error) {
	if !origin.Valid() || len(destinations) == 0 || len(destinations) > maxMatrixDestinations {
		return nil, ErrInvalidMatrix
	}
	for _, destination := range destinations {
		if !destination.Valid() {
			return nil, ErrInvalidMatrix
		}
	}
	key := matrixCacheKey(origin, destinations)
	var matrix domain.Matrix
	if service.cache != nil && service.cache.Get(ctx, key, &matrix) == nil {
		return &matrix, nil
	}
	result, err := service.provider.Matrix(ctx, origin, destinations)
	if err == nil {
		service.cacheSet(ctx, key, result)
	}
	return result, err
}

func (service *LocationService) cacheSet(ctx context.Context, key string, value any) {
	if service.cache == nil {
		return
	}
	if err := service.cache.Set(ctx, key, value); err != nil {
		service.logger.DebugContext(ctx, "store location cache entry failed", "error", err, "operation", "set")
	}
}

func matrixCacheKey(origin domain.Coordinates, destinations []domain.Coordinates) string {
	var builder strings.Builder
	fmt.Fprintf(&builder, "matrix:%.4f:%.4f", origin.Latitude, origin.Longitude)
	for _, destination := range destinations {
		fmt.Fprintf(&builder, ":%.4f:%.4f", destination.Latitude, destination.Longitude)
	}
	return builder.String()
}
