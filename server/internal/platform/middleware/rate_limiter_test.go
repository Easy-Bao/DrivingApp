package middleware

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

type failingCounterStore struct{}

func (failingCounterStore) Increment(context.Context, string, time.Duration) (int64, error) {
	return 0, errors.New("counter store unavailable")
}

func TestRateLimiterRejectsReadRequestsAfterTheirLimit(t *testing.T) {
	config := DefaultRateLimitConfig()
	config.Read = 2
	limiter := NewRateLimiter(NewMemoryCounterStore(), config)
	handler := limiter.Middleware(noContentHandler())

	for index := 0; index < 2; index++ {
		response := serveRateLimitedRequest(handler, http.MethodGet, "/api/v1/rides/1", "192.0.2.10:1234")
		if response.Code != http.StatusNoContent {
			t.Fatalf("request %d status = %d, want %d", index+1, response.Code, http.StatusNoContent)
		}
	}

	response := serveRateLimitedRequest(handler, http.MethodGet, "/api/v1/rides/1", "192.0.2.10:1234")
	if response.Code != http.StatusTooManyRequests {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusTooManyRequests)
	}
	if response.Header().Get("Retry-After") == "" {
		t.Error("rate-limited response did not include Retry-After")
	}
}

func TestRateLimiterUsesSeparateAuthenticationLimit(t *testing.T) {
	config := DefaultRateLimitConfig()
	config.Authentication = 1
	config.Mutation = 10
	handler := NewRateLimiter(NewMemoryCounterStore(), config).Middleware(noContentHandler())

	first := serveRateLimitedRequest(handler, http.MethodPost, "/api/v1/auth/login", "192.0.2.11:1234")
	if first.Code != http.StatusNoContent {
		t.Fatalf("first auth status = %d, want %d", first.Code, http.StatusNoContent)
	}
	second := serveRateLimitedRequest(handler, http.MethodPost, "/api/v1/auth/login", "192.0.2.11:1234")
	if second.Code != http.StatusTooManyRequests {
		t.Fatalf("second auth status = %d, want %d", second.Code, http.StatusTooManyRequests)
	}

	mutation := serveRateLimitedRequest(handler, http.MethodPost, "/api/v1/rides", "192.0.2.11:1234")
	if mutation.Code != http.StatusNoContent {
		t.Fatalf("mutation status = %d, want independent bucket", mutation.Code)
	}
}

func TestRateLimiterProtectsFareCalculationRequests(t *testing.T) {
	config := DefaultRateLimitConfig()
	config.Fare = 1
	handler := NewRateLimiter(NewMemoryCounterStore(), config).Middleware(noContentHandler())

	first := serveRateLimitedRequest(handler, http.MethodPost, "/api/v1/bids/fare", "192.0.2.12:1234")
	if first.Code != http.StatusNoContent {
		t.Fatalf("first fare status = %d, want %d", first.Code, http.StatusNoContent)
	}
	if first.Header().Get("X-RateLimit-Limit") != "1" {
		t.Fatalf("fare request limit header = %q, want 1", first.Header().Get("X-RateLimit-Limit"))
	}

	second := serveRateLimitedRequest(handler, http.MethodPost, "/api/v1/bids/fare", "192.0.2.12:1234")
	if second.Code != http.StatusTooManyRequests {
		t.Fatalf("second fare status = %d, want %d", second.Code, http.StatusTooManyRequests)
	}
}

func TestRateLimiterKeepsTelemetrySeparateFromMutations(t *testing.T) {
	config := DefaultRateLimitConfig()
	config.Telemetry = 1
	config.Mutation = 1
	handler := NewRateLimiter(NewMemoryCounterStore(), config).Middleware(noContentHandler())
	remoteAddr := "192.0.2.13:1234"

	if response := serveRateLimitedRequest(handler, http.MethodPost, "/api/v1/telemetry/location", remoteAddr); response.Code != http.StatusNoContent {
		t.Fatalf("telemetry status = %d", response.Code)
	}
	if response := serveRateLimitedRequest(handler, http.MethodPost, "/api/v1/rides", remoteAddr); response.Code != http.StatusNoContent {
		t.Fatalf("mutation status = %d", response.Code)
	}
	if response := serveRateLimitedRequest(handler, http.MethodPost, "/api/v1/telemetry/location", remoteAddr); response.Code != http.StatusTooManyRequests {
		t.Fatalf("second telemetry status = %d, want %d", response.Code, http.StatusTooManyRequests)
	}
}

func TestRateLimiterClassifiesEveryWorkload(t *testing.T) {
	config := RateLimitConfig{
		Authentication: 11,
		Location:       22,
		Fare:           33,
		Connection:     44,
		Telemetry:      55,
		Mutation:       66,
		Read:           77,
		Window:         time.Minute,
	}
	handler := NewRateLimiter(NewMemoryCounterStore(), config).Middleware(noContentHandler())
	for _, test := range []struct {
		name   string
		method string
		path   string
		limit  string
	}{
		{name: "authentication", method: http.MethodPost, path: "/api/v1/auth/login", limit: "11"},
		{name: "location", method: http.MethodGet, path: "/api/v1/location/search", limit: "22"},
		{name: "fare", method: http.MethodPost, path: "/api/v1/fares/estimate", limit: "33"},
		{name: "connection", method: http.MethodGet, path: "/api/v1/realtime/ws", limit: "44"},
		{name: "telemetry", method: http.MethodPost, path: "/api/v1/telemetry/location", limit: "55"},
		{name: "mutation", method: http.MethodPost, path: "/api/v1/rides", limit: "66"},
		{name: "read", method: http.MethodGet, path: "/api/v1/rides/1", limit: "77"},
	} {
		t.Run(test.name, func(t *testing.T) {
			response := serveRateLimitedRequest(handler, test.method, test.path, "192.0.2.18:1234")
			if value := response.Header().Get("X-RateLimit-Limit"); value != test.limit {
				t.Fatalf("limit = %q, want %q", value, test.limit)
			}
		})
	}
}

func TestRateLimiterDoesNotTrustRawForwardedAddress(t *testing.T) {
	config := DefaultRateLimitConfig()
	config.Read = 1
	handler := NewRateLimiter(NewMemoryCounterStore(), config).Middleware(noContentHandler())

	firstRequest := httptest.NewRequest(http.MethodGet, "/api/v1/rides/1", nil)
	firstRequest.RemoteAddr = "192.0.2.14:1234"
	firstRequest.Header.Set("X-Forwarded-For", "203.0.113.1")
	firstResponse := httptest.NewRecorder()
	handler.ServeHTTP(firstResponse, firstRequest)

	secondRequest := httptest.NewRequest(http.MethodGet, "/api/v1/rides/1", nil)
	secondRequest.RemoteAddr = "192.0.2.14:1234"
	secondRequest.Header.Set("X-Forwarded-For", "203.0.113.2")
	secondResponse := httptest.NewRecorder()
	handler.ServeHTTP(secondResponse, secondRequest)
	if secondResponse.Code != http.StatusTooManyRequests {
		t.Fatalf("status = %d, want spoofed address to share connection bucket", secondResponse.Code)
	}
}

func TestRateLimiterFailsClosedForPublicProtection(t *testing.T) {
	called := false
	handler := NewRateLimiter(failingCounterStore{}, DefaultRateLimitConfig()).Middleware(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		called = true
	}))
	response := serveRateLimitedRequest(handler, http.MethodPost, "/api/v1/auth/login", "192.0.2.15:1234")
	if response.Code != http.StatusServiceUnavailable || called {
		t.Fatalf("status = %d, handler called = %t", response.Code, called)
	}
	if response.Header().Get("Retry-After") != "1" {
		t.Fatalf("Retry-After = %q, want 1", response.Header().Get("Retry-After"))
	}
}

func TestRateLimiterFailsOpenForAuthenticatedTraffic(t *testing.T) {
	for _, test := range []struct {
		name   string
		method string
		path   string
	}{
		{name: "telemetry", method: http.MethodPost, path: "/api/v1/telemetry/location"},
		{name: "command", method: http.MethodPost, path: "/api/v1/rides"},
		{name: "read", method: http.MethodGet, path: "/api/v1/rides/1"},
	} {
		t.Run(test.name, func(t *testing.T) {
			handler := NewRateLimiter(failingCounterStore{}, DefaultRateLimitConfig()).Middleware(noContentHandler())
			response := serveRateLimitedRequest(handler, test.method, test.path, "192.0.2.16:1234")
			if response.Code != http.StatusNoContent {
				t.Fatalf("status = %d, want request to continue", response.Code)
			}
		})
	}
}

func TestRateLimiterBypassesHealthAndPreflight(t *testing.T) {
	handler := NewRateLimiter(failingCounterStore{}, DefaultRateLimitConfig()).Middleware(noContentHandler())
	for _, request := range []struct {
		method string
		path   string
	}{
		{method: http.MethodGet, path: "/health"},
		{method: http.MethodOptions, path: "/api/v1/auth/login"},
	} {
		response := serveRateLimitedRequest(handler, request.method, request.path, "192.0.2.17:1234")
		if response.Code != http.StatusNoContent {
			t.Fatalf("%s %s status = %d", request.method, request.path, response.Code)
		}
	}
}

func TestMemoryCounterStorePrunesExpiredEntries(t *testing.T) {
	store := NewMemoryCounterStore()
	for index := 0; index < memoryCounterCleanupInterval*2; index++ {
		if _, err := store.Increment(context.Background(), fmt.Sprintf("client-%d", index), time.Nanosecond); err != nil {
			t.Fatalf("increment %d: %v", index, err)
		}
	}

	if len(store.entries) >= memoryCounterCleanupInterval*2 {
		t.Fatalf("expired counter entries were retained: %d", len(store.entries))
	}
}

func TestMemoryCounterStoreHonorsCancelledContext(t *testing.T) {
	store := NewMemoryCounterStore()
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	if _, err := store.Increment(ctx, "cancelled", time.Minute); !errors.Is(err, context.Canceled) {
		t.Fatalf("increment error = %v, want context canceled", err)
	}
}

func noContentHandler() http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	})
}

func serveRateLimitedRequest(handler http.Handler, method, path, remoteAddr string) *httptest.ResponseRecorder {
	request := httptest.NewRequest(method, path, nil)
	request.RemoteAddr = remoteAddr
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	return response
}
