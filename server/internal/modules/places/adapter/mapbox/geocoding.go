package mapbox

import (
	"cmp"
	"context"
	"encoding/json"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/places/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/geo"
	"math"
	"net/url"
	"slices"
	"strings"
	"sync"
	"time"
)

func (provider *RoutingProvider) Search(
	ctx context.Context,
	query string,
	origin domain.Coordinates,
) ([]domain.Place, error) {
	if err := provider.validate(); err != nil {
		return nil, err
	}
	if len(query) > _maxSearchQueryBytes || !origin.Valid() {
		return nil, fmt.Errorf("invalid location search")
	}
	queryParams := url.Values{
		"q":            {query},
		"access_token": {provider.token},
		"limit":        {"10"},
		"types":        {"poi,address,place"},
		"proximity":    {coordinate(origin.Longitude) + "," + coordinate(origin.Latitude)},
	}
	var response featureResponse
	if err := provider.getJSON(ctx, _searchURL+"/forward?"+queryParams.Encode(), &response); err != nil {
		return nil, fmt.Errorf("search location provider: %w", err)
	}
	places := make([]domain.Place, 0, len(response.Features))
	for _, feature := range response.Features {
		if place, ok := placeFromFeature(feature, origin); ok {
			places = append(places, place)
		}
	}
	return places, nil
}

func (provider *RoutingProvider) Nearby(
	ctx context.Context,
	origin domain.Coordinates,
	page int,
) ([]domain.Place, error) {
	if err := provider.validate(); err != nil {
		return nil, err
	}
	invalidPage := page < 1 || page > _maxNearbyPage
	if invalidPage || !origin.Valid() {
		return nil, fmt.Errorf("invalid nearby page or coordinates")
	}
	cacheKey := nearbyCacheKey(origin, provider.nearbyCategories)
	if cached, ok := provider.cachedNearby(cacheKey); ok {
		return paginateNearbyPlaces(cached, page), nil
	}

	categories := provider.nearbyCategories
	var places []domain.Place
	if len(categories) == 0 {
		result := provider.nearbyCategory(
			ctx,
			origin,
			_defaultNearbyCategoriesCSV,
		)
		if result.err != nil {
			return nil, result.err
		}
		places = result.places
	} else {
		results := make([]categoryResult, 0, len(categories))
		var resultsMu sync.Mutex
		var waitGroup sync.WaitGroup
		for _, category := range categories {
			waitGroup.Go(func() {
				result := provider.nearbyCategory(ctx, origin, category)
				resultsMu.Lock()
				results = append(results, result)
				resultsMu.Unlock()
			})
		}
		waitGroup.Wait()

		places = make([]domain.Place, 0)
		var firstErr error
		for _, result := range results {
			if result.err != nil {
				if firstErr == nil {
					firstErr = result.err
				}
				continue
			}
			places = append(places, result.places...)
		}
		if len(places) == 0 && firstErr != nil {
			return nil, firstErr
		}
	}

	places = uniqueNearbyPlaces(places)
	slices.SortStableFunc(places, func(left, right domain.Place) int {
		if distanceOrder := cmp.Compare(left.DistanceKm, right.DistanceKm); distanceOrder != 0 {
			return distanceOrder
		}
		return cmp.Compare(left.Name, right.Name)
	})
	provider.storeNearby(cacheKey, places)

	return paginateNearbyPlaces(places, page), nil
}

func nearbyCacheKey(origin domain.Coordinates, categories []string) string {
	base := fmt.Sprintf("%.4f,%.4f", origin.Latitude, origin.Longitude)
	if len(categories) == 0 {
		return base
	}
	return base + "|" + strings.Join(categories, ",")
}

func (provider *RoutingProvider) cachedNearby(key string) ([]domain.Place, bool) {
	provider.nearbyCacheMu.Lock()
	defer provider.nearbyCacheMu.Unlock()
	entry, ok := provider.nearbyCache[key]
	if !ok {
		return nil, false
	}
	if time.Since(entry.createdAt) >= _nearbyCacheTTL {
		delete(provider.nearbyCache, key)
		return nil, false
	}
	return slices.Clone(entry.places), true
}

func (provider *RoutingProvider) storeNearby(key string, places []domain.Place) {
	provider.nearbyCacheMu.Lock()
	defer provider.nearbyCacheMu.Unlock()
	if provider.nearbyCache == nil {
		provider.nearbyCache = make(map[string]nearbyCacheEntry)
	}
	if _, exists := provider.nearbyCache[key]; !exists && len(provider.nearbyCache) >= _nearbyCacheMaxEntries {
		oldestKey := ""
		var oldest time.Time
		for candidateKey, candidate := range provider.nearbyCache {
			if oldestKey == "" || candidate.createdAt.Before(oldest) {
				oldestKey = candidateKey
				oldest = candidate.createdAt
			}
		}
		delete(provider.nearbyCache, oldestKey)
	}
	provider.nearbyCache[key] = nearbyCacheEntry{
		places:    slices.Clone(places),
		createdAt: time.Now(),
	}
}

func escapeCategoryPath(category string) string {
	parts := strings.Split(category, ",")
	for index, part := range parts {
		parts[index] = url.PathEscape(strings.TrimSpace(part))
	}
	return strings.Join(parts, ",")
}

func paginateNearbyPlaces(places []domain.Place, page int) []domain.Place {
	start := (page - 1) * _nearbyPageSize
	if start >= len(places) {
		return []domain.Place{}
	}
	end := min(start+_nearbyPageSize, len(places))
	return slices.Clone(places[start:end])
}

func (provider *RoutingProvider) nearbyCategory(
	ctx context.Context,
	origin domain.Coordinates,
	category string,
) categoryResult {
	queryParams := url.Values{
		"access_token": {provider.token},
		"limit":        {"25"},
		"proximity":    {coordinate(origin.Longitude) + "," + coordinate(origin.Latitude)},
	}
	var response featureResponse
	endpoint := _searchURL + "/category/" + escapeCategoryPath(category) + "?" + queryParams.Encode()
	if err := provider.getJSON(ctx, endpoint, &response); err != nil {
		return categoryResult{err: fmt.Errorf("search nearby category %q: %w", category, err)}
	}
	places := make([]domain.Place, 0, len(response.Features))
	for _, feature := range response.Features {
		if place, ok := placeFromFeature(feature, origin); ok {
			places = append(places, place)
		}
	}
	return categoryResult{places: places}
}

func placeFromFeature(feature feature, origin domain.Coordinates) (domain.Place, bool) {
	longitude, latitude, ok := featureCoordinates(feature)
	if !ok {
		return domain.Place{}, false
	}
	name := feature.Properties.Name
	if name == "" {
		name = feature.Properties.PreferredName
	}
	if name == "" {
		name = feature.Properties.ShortAddress
	}
	if name == "" {
		name = feature.Properties.PlaceFormatted
	}
	address := feature.Properties.Address
	if address == "" {
		address = feature.Properties.ShortAddress
	}
	if address == "" {
		address = feature.Properties.PlaceFormatted
	}
	return domain.Place{
		ID:         featureID(feature),
		Name:       name,
		Address:    address,
		Category:   categoryName(feature.Properties.Category),
		Longitude:  longitude,
		Latitude:   latitude,
		DistanceKm: geo.DistanceKm(origin.Latitude, origin.Longitude, latitude, longitude),
		Context:    featureContextNames(feature),
	}, true
}

func categoryName(raw json.RawMessage) string {
	categories := categoryValues(raw)
	if len(categories) > 0 {
		return categories[0]
	}
	return ""
}

func uniqueNearbyPlaces(places []domain.Place) []domain.Place {
	seen := make(map[string]struct{}, len(places))
	unique := make([]domain.Place, 0, len(places))
	for _, place := range places {
		key := place.ID
		if key == "" {
			key = coordinate(place.Latitude) + "," + coordinate(place.Longitude)
		}
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		unique = append(unique, place)
	}
	return unique
}

func (provider *RoutingProvider) ReverseGeocode(
	ctx context.Context,
	coordinates domain.Coordinates,
) (*domain.Place, error) {
	if err := provider.validate(); err != nil {
		return nil, err
	}
	queryParams := url.Values{
		"longitude":    {coordinate(coordinates.Longitude)},
		"latitude":     {coordinate(coordinates.Latitude)},
		"access_token": {provider.token},
		"limit":        {"10"},
	}
	var response featureResponse
	if err := provider.getJSON(ctx, _searchURL+"/reverse?"+queryParams.Encode(), &response); err != nil {
		return nil, fmt.Errorf("reverse geocode location: %w", err)
	}
	selected, match, ok := mostSpecificReverseFeature(response.Features, coordinates)
	if !ok {
		fallbackQuery := url.Values{
			"longitude":    {coordinate(coordinates.Longitude)},
			"latitude":     {coordinate(coordinates.Latitude)},
			"access_token": {provider.token},
			"limit":        {"1"},
		}
		if err := provider.getJSON(ctx, _geocodingURL+"/reverse?"+fallbackQuery.Encode(), &response); err != nil {
			return nil, fmt.Errorf("reverse geocode location fallback: %w", err)
		}
		selected, match, ok = mostSpecificReverseFeature(response.Features, coordinates)
	}
	if !ok {
		return nil, fmt.Errorf("mapbox returned no place")
	}
	place, ok := placeFromFeature(selected, coordinates)
	if !ok {
		return nil, fmt.Errorf("mapbox returned an invalid place")
	}
	place.MatchType = match.matchType
	place.DistanceMeters = match.distanceMeters
	place.Confidence = match.confidence
	return &place, nil
}

func mostSpecificReverseFeature(features []feature, origin domain.Coordinates) (feature, reverseMatch, bool) {
	var selected feature
	var selectedMatch reverseMatch
	selectedRank := reverseCandidateRank{stage: math.MaxInt, prominence: -1, distanceMeters: math.MaxFloat64}
	found := false
	for _, candidate := range features {
		longitude, latitude, ok := featureCoordinates(candidate)
		if !ok {
			continue
		}
		distanceMeters := geo.DistanceMeters(origin.Latitude, origin.Longitude, latitude, longitude)
		rank := reverseCandidateRankFor(candidate, distanceMeters)
		isEarlierStage := rank.stage < selectedRank.stage
		isMoreProminent := rank.stage == selectedRank.stage && rank.prominence > selectedRank.prominence
		isCloser := rank.stage == selectedRank.stage &&
			rank.prominence == selectedRank.prominence &&
			rank.distanceMeters < selectedRank.distanceMeters
		if !found || isEarlierStage || isMoreProminent || isCloser {
			selected = candidate
			selectedMatch = reverseMatchFor(candidate, distanceMeters)
			selectedRank = rank
			found = true
		}
	}
	return selected, selectedMatch, found
}

func reverseCandidateRankFor(candidate feature, distanceMeters float64) reverseCandidateRank {
	featureType := featureType(candidate)
	stage := 4
	switch {
	case distanceMeters <= 15 && (featureType == "address" || featureType == "poi"):
		stage = 0
	case distanceMeters <= 100 && (featureType == "address" || featureType == "poi"):
		stage = 1
	case featureType == "street":
		stage = 2
	case featureType == "locality" || featureType == "place" || featureType == "district" || featureType == "region":
		stage = 3
	}
	return reverseCandidateRank{
		stage:          stage,
		prominence:     reverseFeatureProminence(candidate),
		distanceMeters: distanceMeters,
	}
}

func reverseMatchFor(candidate feature, distanceMeters float64) reverseMatch {
	featureType := featureType(candidate)
	accuracy := strings.ToLower(candidate.Properties.Coordinates.Accuracy)
	matchType := "area"
	switch {
	case distanceMeters <= 15 && (accuracy == "rooftop" || accuracy == "parcel" || accuracy == "point"):
		matchType = "direct"
	case distanceMeters <= 100 && featureType == "poi":
		matchType = "nearby_poi"
	case distanceMeters <= 100 && featureType == "address":
		matchType = "interpolated"
	case featureType == "street":
		matchType = "road"
	}
	return reverseMatch{
		matchType:      matchType,
		distanceMeters: distanceMeters,
		confidence:     reverseConfidence(matchType, distanceMeters),
	}
}

func reverseFeatureProminence(candidate feature) int {
	featureType := featureType(candidate)
	if featureType != "poi" {
		switch featureType {
		case "address":
			return 5
		case "street":
			return 4
		case "locality", "place", "district", "region":
			return 2
		default:
			return 1
		}
	}
	prominence := 6
	for _, rawCategory := range categoryValues(candidate.Properties.Category) {
		category := strings.ToLower(rawCategory)
		isHighProminenceCategory := strings.Contains(category, "transit") ||
			strings.Contains(category, "airport") ||
			strings.Contains(category, "hospital")
		if isHighProminenceCategory {
			prominence = 10
			break
		}
		isMediumProminenceCategory := strings.Contains(category, "university") ||
			strings.Contains(category, "school") ||
			strings.Contains(category, "government")
		if isMediumProminenceCategory {
			prominence = 9
		}
	}
	return prominence
}

func categoryValues(raw json.RawMessage) []string {
	if len(raw) == 0 {
		return []string{}
	}
	categories := []string{}
	if json.Unmarshal(raw, &categories) == nil {
		return categories
	}
	var category string
	if json.Unmarshal(raw, &category) == nil && category != "" {
		return []string{category}
	}
	return []string{}
}

func reverseConfidence(matchType string, distanceMeters float64) float64 {
	base := map[string]float64{
		"direct":       0.98,
		"interpolated": 0.82,
		"nearby_poi":   0.76,
		"road":         0.64,
		"area":         0.45,
	}[matchType]
	confidence := base - math.Min(distanceMeters/1000, 1)*0.15
	return math.Max(0.1, math.Round(confidence*100)/100)
}

func featureType(candidate feature) string {
	result := strings.ToLower(candidate.Properties.FeatureType)
	if result == "" {
		result = strings.ToLower(candidate.FeatureType)
	}
	return result
}

func featureID(candidate feature) string {
	if candidate.ID != "" {
		return candidate.ID
	}
	return candidate.Properties.MapboxID
}

func featureCoordinates(candidate feature) (float64, float64, bool) {
	if len(candidate.Geometry.Coordinates) >= 2 {
		longitude := candidate.Geometry.Coordinates[0]
		latitude := candidate.Geometry.Coordinates[1]
		return longitude, latitude, (domain.Coordinates{Latitude: latitude, Longitude: longitude}).Valid()
	}
	if candidate.Properties.Coordinates.Longitude == nil || candidate.Properties.Coordinates.Latitude == nil {
		return 0, 0, false
	}
	longitude := *candidate.Properties.Coordinates.Longitude
	latitude := *candidate.Properties.Coordinates.Latitude
	return longitude, latitude, (domain.Coordinates{Latitude: latitude, Longitude: longitude}).Valid()
}

func featureContextNames(candidate feature) map[string]string {
	if len(candidate.Properties.Context) == 0 {
		return nil
	}
	contextNames := make(map[string]string, len(candidate.Properties.Context))
	for key, value := range candidate.Properties.Context {
		if strings.TrimSpace(value.Name) != "" {
			contextNames[key] = value.Name
		}
	}
	if len(contextNames) == 0 {
		return nil
	}
	return contextNames
}
