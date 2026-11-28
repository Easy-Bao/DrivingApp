package mapbox

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	locationports "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/places/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/resilience"
	"io"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	_searchURL                      = "https://api.mapbox.com/search/searchbox/v1"
	_geocodingURL                   = "https://api.mapbox.com/search/geocode/v6"
	_directionsURL                  = "https://api.mapbox.com/directions/v5/mapbox"
	_matrixURL                      = "https://api.mapbox.com/directions-matrix/v1/mapbox/driving"
	_nearbyPageSize                 = 10
	_maxNearbyPage                  = 100
	_maxSearchQueryBytes            = 256
	_maxProviderResponseBytes int64 = 4 << 20
	_mapboxRequestTimeout           = 10 * time.Second
	_routeCacheTTL                  = 15 * time.Second
	_routeCacheMaxEntries           = 128
	_nearbyCacheTTL                 = 2 * time.Minute
	_nearbyCacheMaxEntries          = 128
)

const _defaultNearbyCategoriesCSV = "food_and_drink,hotel,hospital,school,gas_station,bank,shopping_mall,park"

type RoutingProvider struct {
	token            string
	client           *http.Client
	breaker          *resilience.CircuitBreaker
	nearbyCategories []string
	routeCacheMu     sync.Mutex
	routeCache       map[string]routeCacheEntry
	nearbyCacheMu    sync.Mutex
	nearbyCache      map[string]nearbyCacheEntry
}

var _ locationports.Provider = (*RoutingProvider)(nil)

type routeCacheEntry struct {
	routes    []cachedRoute
	createdAt time.Time
}

type nearbyCacheEntry struct {
	places    []domain.Place
	createdAt time.Time
}

func NewRoutingProvider(token string) *RoutingProvider {
	baseTransport, ok := http.DefaultTransport.(*http.Transport)
	if !ok || baseTransport == nil {
		baseTransport = &http.Transport{}
	}
	transport := baseTransport.Clone()
	// The default resolver can select an unreachable IPv6 path locally, leaving
	// Mapbox's HTTP/2 response waiting until the client timeout.
	transport.ForceAttemptHTTP2 = true
	dialer := &net.Dialer{Timeout: 5 * time.Second, KeepAlive: 30 * time.Second}
	transport.DialContext = func(ctx context.Context, _, address string) (net.Conn, error) {
		return dialer.DialContext(ctx, "tcp4", address)
	}
	return &RoutingProvider{
		token:  token,
		client: &http.Client{Transport: transport, Timeout: _mapboxRequestTimeout},
		breaker: resilience.NewCircuitBreaker(resilience.CircuitBreakerConfig{
			FailureThreshold: 5,
			ResetAfter:       30 * time.Second,
		}),
		routeCache:  make(map[string]routeCacheEntry),
		nearbyCache: make(map[string]nearbyCacheEntry),
	}
}

func (provider *RoutingProvider) getJSON(ctx context.Context, endpoint string, target any) error {
	if err := provider.validate(); err != nil {
		return err
	}
	return provider.breaker.Do(ctx, func(ctx context.Context) error {
		return provider.fetchJSON(ctx, endpoint, target)
	})
}

func (provider *RoutingProvider) validate() error {
	if provider == nil || provider.client == nil {
		return fmt.Errorf("location provider is not configured")
	}
	if strings.TrimSpace(provider.token) == "" {
		return fmt.Errorf("location provider access token is not configured")
	}
	if provider.breaker == nil {
		return resilience.ErrCircuitNotConfigured
	}
	return nil
}

func (provider *RoutingProvider) fetchJSON(ctx context.Context, endpoint string, target any) (err error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return fmt.Errorf("create location provider request: %w", sanitizeMapboxError(err))
	}
	response, err := provider.client.Do(request)
	if err != nil {
		return fmt.Errorf("send location provider request: %w", sanitizeMapboxError(err))
	}
	defer func() {
		if closeErr := response.Body.Close(); closeErr != nil {
			closeErr = fmt.Errorf("close location provider response: %w", closeErr)
			if err == nil {
				err = closeErr
				return
			}
			err = errors.Join(err, closeErr)
		}
	}()
	if response.StatusCode < http.StatusOK || response.StatusCode >= http.StatusMultipleChoices {
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 4<<10))
		statusErr := fmt.Errorf("location provider returned status %d", response.StatusCode)
		if isClientQueryError(response.StatusCode) {
			return resilience.NonTripError{Err: statusErr}
		}
		return statusErr
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, _maxProviderResponseBytes+1))
	if err != nil {
		return fmt.Errorf("read location provider response: %w", err)
	}
	if int64(len(body)) > _maxProviderResponseBytes {
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 4<<10))
		return fmt.Errorf("location provider response exceeds %d bytes", _maxProviderResponseBytes)
	}
	if err := json.Unmarshal(body, target); err != nil {
		return fmt.Errorf("decode location provider response: %w", err)
	}
	return nil
}

func isClientQueryError(statusCode int) bool {
	return statusCode >= http.StatusBadRequest &&
		statusCode < http.StatusInternalServerError &&
		statusCode != http.StatusUnauthorized &&
		statusCode != http.StatusForbidden &&
		statusCode != http.StatusTooManyRequests
}

func sanitizeMapboxError(err error) error {
	var urlErr *url.Error
	if !errors.As(err, &urlErr) || urlErr == nil {
		return err
	}
	sanitized := *urlErr
	if parsed, parseErr := url.Parse(urlErr.URL); parseErr == nil {
		query := parsed.Query()
		if query.Has("access_token") {
			query.Set("access_token", "REDACTED")
			parsed.RawQuery = query.Encode()
		}
		sanitized.URL = parsed.String()
	} else if idx := strings.IndexByte(urlErr.URL, '?'); idx >= 0 {
		sanitized.URL = urlErr.URL[:idx]
	}
	if sanitized.Err != nil {
		sanitized.Err = sanitizeMapboxError(sanitized.Err)
	}
	return &sanitized
}

const _coordinatePrecision = 6

func coordinate(value float64) string {
	return strconv.FormatFloat(value, 'f', _coordinatePrecision, 64)
}
