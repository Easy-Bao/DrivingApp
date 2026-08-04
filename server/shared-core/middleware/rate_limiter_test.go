package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

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
