package usecase

import (
	"context"
	"fmt"
	"location-service/internal/domain"
	"math"
	"sort"
	"strings"
	"sync"
	"time"
	"unicode"
)

const (
	nearbyRadiusKm   = 5.0
	searchRadiusKm   = 10.0
	nearbyPageSize   = 10
	reverseMemoryTTL = 24 * time.Hour
	matrixMemoryTTL  = 15 * time.Second
)

type LocationUseCase interface {
	ReverseGeocode(ctx context.Context, lat, lng float64) (*domain.Place, error)
	SearchPlaces(ctx context.Context, query string, lat, lng float64) ([]domain.Place, error)
	GetNearbyPois(ctx context.Context, lat, lng float64, page int) ([]domain.Place, error)
	GetRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*domain.Route, error)
	GetTravelMatrix(ctx context.Context, origin domain.Point, destinations []domain.Point) (*domain.MatrixResult, error)
}

type locationUseCase struct {
	repo      domain.LocationRepository
	cache     domain.CacheRepository
	queue     domain.QueuePublisher
	requestMu sync.Mutex
	inFlight  map[string]*sharedRequest
	memory    map[string]memoryEntry
}

type sharedRequest struct {
	done  chan struct{}
	value interface{}
	err   error
}

type memoryEntry struct {
	value     interface{}
	expiresAt time.Time
}

func NewLocationUseCase(
	repo domain.LocationRepository,
	cache domain.CacheRepository,
	queue domain.QueuePublisher,
) LocationUseCase {
	return &locationUseCase{
		repo:     repo,
		cache:    cache,
		queue:    queue,
		inFlight: make(map[string]*sharedRequest),
		memory:   make(map[string]memoryEntry),
	}
}

func (uc *locationUseCase) ReverseGeocode(ctx context.Context, lat, lng float64) (*domain.Place, error) {
	key := fmt.Sprintf("reverse:v2:%.4f:%.4f", lat, lng)
	if cached, ok := uc.getMemory(key); ok {
		return cached.(*domain.Place), nil
	}
	if uc.cache != nil {
		if cached, err := uc.cache.GetGeocodeCache(ctx, lat, lng); err == nil && cached != nil {
			uc.setMemory(key, cached, reverseMemoryTTL)
			return cached, nil
		}
	}

	result, err := uc.share(ctx, key, func(requestCtx context.Context) (interface{}, error) {
		place, requestErr := uc.repo.ReverseGeocode(requestCtx, lat, lng)
		if requestErr != nil || place == nil {
			return place, requestErr
		}

		if uc.cache != nil {
			_ = uc.cache.SetGeocodeCache(requestCtx, lat, lng, place)
		}
		uc.setMemory(key, place, reverseMemoryTTL)
		if uc.queue != nil {
			_ = uc.queue.PublishLocationEvent(requestCtx, &domain.LocationUpdateEvent{
				ID:        fmt.Sprintf("loc-%d", time.Now().UnixNano()),
				DriverID:  "system",
				Latitude:  lat,
				Longitude: lng,
				Timestamp: time.Now(),
			})
		}
		return place, nil
	})
	if err != nil {
		return nil, err
	}
	place, ok := result.(*domain.Place)
	if !ok || place == nil {
		return nil, nil
	}
	return place, nil
}

func (uc *locationUseCase) SearchPlaces(ctx context.Context, query string, lat, lng float64) ([]domain.Place, error) {
	originalQuery := strings.TrimSpace(query)
	query = searchCacheQuery(originalQuery)
	if query == "" {
		return []domain.Place{}, nil
	}
	key := fmt.Sprintf("search:%s:%.3f:%.3f", query, lat, lng)
	if cached, ok := uc.getMemory(key); ok {
		return filterSearchPlaces(cached.([]domain.Place)), nil
	}
	if uc.cache != nil {
		if cached, err := uc.cache.GetSearchCache(ctx, query, lat, lng); err == nil && cached != nil {
			cached = filterSearchPlaces(cached)
			uc.setMemory(key, cached, 10*time.Minute)
			return cached, nil
		}
	}
	result, err := uc.share(ctx, key, func(requestCtx context.Context) (interface{}, error) {
		places, requestErr := uc.repo.SearchPlaces(requestCtx, originalQuery, lat, lng)
		places = filterSearchPlaces(places)
		if requestErr == nil && uc.cache != nil {
			_ = uc.cache.SetSearchCache(requestCtx, query, lat, lng, places)
		}
		if requestErr == nil {
			uc.setMemory(key, places, 10*time.Minute)
		}
		return places, requestErr
	})
	if err != nil {
		return nil, err
	}
	return result.([]domain.Place), nil
}

func normalizeSearchQuery(query string) string {
	var builder strings.Builder
	for _, character := range strings.ToLower(strings.TrimSpace(query)) {
		if unicode.IsLetter(character) || unicode.IsDigit(character) {
			builder.WriteRune(character)
			continue
		}
		builder.WriteRune(' ')
	}
	return strings.Join(strings.Fields(builder.String()), " ")
}

func searchCacheQuery(query string) string {
	normalized := normalizeSearchQuery(query)
	compact := strings.ReplaceAll(normalized, " ", "")
	if len([]rune(compact)) >= 2 && len([]rune(compact)) <= 4 && isLettersOnly(compact) {
		return compact
	}
	return normalized
}

func isLettersOnly(value string) bool {
	for _, character := range value {
		if !unicode.IsLetter(character) {
			return false
		}
	}
	return true
}

func filterSearchPlaces(places []domain.Place) []domain.Place {
	filtered := make([]domain.Place, 0, len(places))
	for _, place := range places {
		if place.DistanceKm <= searchRadiusKm {
			filtered = append(filtered, place)
		}
	}
	sort.SliceStable(filtered, func(i, j int) bool {
		return filtered[i].DistanceKm < filtered[j].DistanceKm
	})
	return filtered
}

func (uc *locationUseCase) GetNearbyPois(ctx context.Context, lat, lng float64, page int) ([]domain.Place, error) {
	key := fmt.Sprintf("nearby:%.3f:%.3f:%d", lat, lng, page)
	if cached, ok := uc.getMemory(key); ok {
		return filterAndPageNearbyPlaces(cached.([]domain.Place), page), nil
	}
	if uc.cache != nil {
		if cached, err := uc.cache.GetNearbyCache(ctx, lat, lng, page); err == nil && cached != nil {
			filtered := filterAndPageNearbyPlaces(cached, page)
			uc.setMemory(key, filtered, time.Hour)
			return filtered, nil
		}
	}

	result, err := uc.share(ctx, key, func(requestCtx context.Context) (interface{}, error) {
		return uc.repo.GetNearbyPois(requestCtx, lat, lng, page)
	})
	if err != nil {
		return nil, err
	}
	places := result.([]domain.Place)

	places = filterAndPageNearbyPlaces(places, page)

	if uc.cache != nil && len(places) > 0 {
		_ = uc.cache.SetNearbyCache(ctx, lat, lng, page, places)
	}
	uc.setMemory(key, places, time.Hour)

	return places, nil
}

func filterAndPageNearbyPlaces(places []domain.Place, page int) []domain.Place {
	if page < 1 {
		page = 1
	}

	filtered := make([]domain.Place, 0, len(places))
	for _, place := range places {
		if place.DistanceKm <= nearbyRadiusKm {
			filtered = append(filtered, place)
		}
	}

	sort.SliceStable(filtered, func(i, j int) bool {
		return filtered[i].DistanceKm < filtered[j].DistanceKm
	})

	start := (page - 1) * nearbyPageSize
	if start >= len(filtered) {
		return []domain.Place{}
	}
	end := start + nearbyPageSize
	if end > len(filtered) {
		end = len(filtered)
	}
	return filtered[start:end]
}

func (uc *locationUseCase) GetRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*domain.Route, error) {
	key := fmt.Sprintf("route:v2:%.5f:%.5f:%.5f:%.5f", originLat, originLng, destLat, destLng)
	if cached, ok := uc.getMemory(key); ok {
		return cached.(*domain.Route), nil
	}
	if uc.cache != nil {
		if cached, err := uc.cache.GetRouteCache(ctx, originLat, originLng, destLat, destLng); err == nil && cached != nil {
			uc.setMemory(key, cached, 30*time.Minute)
			return cached, nil
		}
	}
	result, err := uc.share(ctx, key, func(requestCtx context.Context) (interface{}, error) {
		route, requestErr := uc.repo.GetRoute(requestCtx, originLat, originLng, destLat, destLng)
		if requestErr == nil && route != nil && uc.cache != nil {
			_ = uc.cache.SetRouteCache(requestCtx, route)
		}
		if requestErr == nil && route != nil {
			uc.setMemory(key, route, 30*time.Minute)
		}
		return route, requestErr
	})
	if err != nil {
		return nil, err
	}
	return result.(*domain.Route), nil
}

func (uc *locationUseCase) GetTravelMatrix(ctx context.Context, origin domain.Point, destinations []domain.Point) (*domain.MatrixResult, error) {
	if len(destinations) == 0 {
		return &domain.MatrixResult{}, nil
	}
	if len(destinations) > 24 {
		destinations = destinations[:24]
	}
	key := matrixCacheKey(origin, destinations)
	if cached, ok := uc.getMemory(key); ok {
		return cached.(*domain.MatrixResult), nil
	}
	result, err := uc.share(ctx, key, func(requestCtx context.Context) (interface{}, error) {
		matrix, requestErr := uc.repo.GetTravelMatrix(requestCtx, origin, destinations)
		if requestErr == nil && matrix != nil {
			uc.setMemory(key, matrix, matrixMemoryTTL)
		}
		return matrix, requestErr
	})
	if err != nil {
		return nil, err
	}
	matrix, ok := result.(*domain.MatrixResult)
	if !ok || matrix == nil {
		return nil, nil
	}
	return matrix, nil
}

func matrixCacheKey(origin domain.Point, destinations []domain.Point) string {
	key := fmt.Sprintf("matrix:v1:%.5f:%.5f", origin.Latitude, origin.Longitude)
	for _, destination := range destinations {
		key += fmt.Sprintf(":%.5f:%.5f", destination.Latitude, destination.Longitude)
	}
	return key
}

func (uc *locationUseCase) getMemory(key string) (interface{}, bool) {
	uc.requestMu.Lock()
	defer uc.requestMu.Unlock()
	entry, ok := uc.memory[key]
	if !ok {
		return nil, false
	}
	if time.Now().After(entry.expiresAt) {
		delete(uc.memory, key)
		return nil, false
	}
	return entry.value, true
}

func (uc *locationUseCase) setMemory(key string, value interface{}, ttl time.Duration) {
	uc.requestMu.Lock()
	defer uc.requestMu.Unlock()
	uc.memory[key] = memoryEntry{value: value, expiresAt: time.Now().Add(ttl)}
}

func (uc *locationUseCase) share(ctx context.Context, key string, request func(context.Context) (interface{}, error)) (interface{}, error) {
	uc.requestMu.Lock()
	if existing, ok := uc.inFlight[key]; ok {
		uc.requestMu.Unlock()
		select {
		case <-existing.done:
			return existing.value, existing.err
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}
	current := &sharedRequest{done: make(chan struct{})}
	uc.inFlight[key] = current
	uc.requestMu.Unlock()

	value, err := request(ctx)
	uc.requestMu.Lock()
	current.value = value
	current.err = err
	delete(uc.inFlight, key)
	close(current.done)
	uc.requestMu.Unlock()
	return value, err
}

func CalculateHaversine(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadiusKm = 6371.0
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLng := (lng2 - lng1) * math.Pi / 180.0

	a := math.Sin(dLat/2.0)*math.Sin(dLat/2.0) +
		math.Cos(lat1*math.Pi/180.0)*math.Cos(lat2*math.Pi/180.0)*
			math.Sin(dLng/2.0)*math.Sin(dLng/2.0)
	c := 2.0 * math.Asin(math.Sqrt(a))

	return earthRadiusKm * c
}
