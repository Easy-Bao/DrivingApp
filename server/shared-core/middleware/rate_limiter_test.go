package middleware

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

type failingCounterStore struct{}

func (failingCounterStore) Increment(context.Context, string, time.Duration) (int64, error) {
	return 0, errors.New("counter store unavailable")
}

func TestRateLimiterRejectsRequestsAfterLimit(t *testing.T) {
	limiter := NewRateLimiter(NewMemoryCounterStore(), 2, 2, time.Minute)
	handler := limiter.Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))

	for index := 0; index < 2; index++ {
		request := httptest.NewRequest(http.MethodGet, "/rides", nil)
		request.RemoteAddr = "192.0.2.10:1234"
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != http.StatusNoContent {
			t.Fatalf("request %d status = %d, want %d", index+1, response.Code, http.StatusNoContent)
		}
	}

	request := httptest.NewRequest(http.MethodGet, "/rides", nil)
	request.RemoteAddr = "192.0.2.10:1234"
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusTooManyRequests {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusTooManyRequests)
	}
	if response.Header().Get("Retry-After") == "" {
		t.Error("rate-limited response did not include Retry-After")
	}
}

func TestRateLimiterUsesSeparateAuthLimit(t *testing.T) {
	limiter := NewRateLimiter(NewMemoryCounterStore(), 10, 1, time.Minute)
	handler := limiter.Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))

	first := httptest.NewRequest(http.MethodPost, "/auth/login", nil)
	first.RemoteAddr = "192.0.2.11:1234"
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, first)
	if response.Code != http.StatusNoContent {
		t.Fatalf("first auth status = %d, want %d", response.Code, http.StatusNoContent)
	}

	second := httptest.NewRequest(http.MethodPost, "/auth/login", nil)
	second.RemoteAddr = "192.0.2.11:1234"
	response = httptest.NewRecorder()
	handler.ServeHTTP(response, second)
	if response.Code != http.StatusTooManyRequests {
		t.Fatalf("second auth status = %d, want %d", response.Code, http.StatusTooManyRequests)
	}
}

func TestRateLimiterProtectsFareCalculationRequests(t *testing.T) {
	limiter := NewRateLimiter(NewMemoryCounterStore(), 1, 1, time.Minute)
	handler := limiter.Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))

	request := httptest.NewRequest(http.MethodPost, "/api/v1/bids/fare", nil)
	request.RemoteAddr = "192.0.2.12:1234"
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusNoContent {
		t.Fatalf("first fare status = %d, want %d", response.Code, http.StatusNoContent)
	}
	if response.Header().Get("X-RateLimit-Limit") != "1" {
		t.Fatalf("fare request limit header = %q, want 1", response.Header().Get("X-RateLimit-Limit"))
	}

	request = httptest.NewRequest(http.MethodPost, "/api/v1/bids/fare", nil)
	request.RemoteAddr = "192.0.2.12:1234"
	response = httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusTooManyRequests {
		t.Fatalf("second fare status = %d, want %d", response.Code, http.StatusTooManyRequests)
	}
}

func TestRateLimiterFailsClosedWhenCounterStoreIsUnavailable(t *testing.T) {
	called := false
	limiter := NewRateLimiter(failingCounterStore{}, 10, 10, time.Minute)
	handler := limiter.Middleware(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		called = true
	}))
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest(http.MethodPost, "/rides", nil))
	if response.Code != http.StatusServiceUnavailable || called {
		t.Fatalf("status = %d, handler called = %t", response.Code, called)
	}
	if response.Header().Get("Retry-After") != "1" {
		t.Fatalf("Retry-After = %q, want 1", response.Header().Get("Retry-After"))
	}
}
