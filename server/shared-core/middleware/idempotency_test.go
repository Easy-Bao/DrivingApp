package middleware

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

type failingIdempotencyStore struct{}

func (failingIdempotencyStore) Get(context.Context, string) ([]byte, error) {
	return nil, errors.New("idempotency store unavailable")
}
func (failingIdempotencyStore) Set(context.Context, string, []byte, time.Duration) error {
	return errors.New("idempotency store unavailable")
}
func (failingIdempotencyStore) SetNX(context.Context, string, []byte, time.Duration) (bool, error) {
	return false, errors.New("idempotency store unavailable")
}
func (failingIdempotencyStore) Delete(context.Context, string) error { return nil }

func TestIdempotencyReplaysSuccessfulResponse(t *testing.T) {
	var calls atomic.Int32
	handler := NewIdempotency(NewMemoryIdempotencyStore(), time.Minute).Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		writer.Header().Set("Content-Type", "application/json")
		writer.WriteHeader(http.StatusCreated)
		_, _ = writer.Write([]byte(`{"created":true}`))
	}))

	for index := 0; index < 2; index++ {
		request := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_centavos":100}`))
		request.Header.Set("Idempotency-Key", "ride-key-1")
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != http.StatusCreated {
			t.Fatalf("request %d status = %d, want %d", index+1, response.Code, http.StatusCreated)
		}
		if body, _ := io.ReadAll(response.Body); string(body) != `{"created":true}` {
			t.Fatalf("request %d body = %s", index+1, body)
		}
	}
	if calls.Load() != 1 {
		t.Fatalf("handler calls = %d, want 1", calls.Load())
	}
}

func TestIdempotencyRejectsKeyReuseWithDifferentBody(t *testing.T) {
	store := NewMemoryIdempotencyStore()
	handler := NewIdempotency(store, time.Minute).Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusCreated)
	}))

	first := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_centavos":100}`))
	first.Header.Set("Idempotency-Key", "ride-key-2")
	handler.ServeHTTP(httptest.NewRecorder(), first)

	second := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_centavos":200}`))
	second.Header.Set("Idempotency-Key", "ride-key-2")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, second)
	if response.Code != http.StatusConflict {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusConflict)
	}
}

func TestIdempotencyFailsClosedWhenStoreIsUnavailable(t *testing.T) {
	called := false
	handler := NewIdempotency(failingIdempotencyStore{}, time.Minute).Middleware(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		called = true
	}))
	request := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_centavos":100}`))
	request.Header.Set("Idempotency-Key", "ride-key-3")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusServiceUnavailable || called {
		t.Fatalf("status = %d, handler called = %t", response.Code, called)
	}
}

func TestIdempotencySkipsHighThroughputTelemetryUpdates(t *testing.T) {
	var calls atomic.Int32
	handler := NewIdempotency(NewMemoryIdempotencyStore(), time.Minute).Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		writer.WriteHeader(http.StatusAccepted)
	}))

	for index := 0; index < 2; index++ {
		request := httptest.NewRequest(http.MethodPost, "/api/v1/telemetry/location", strings.NewReader(`{"lat":7.8,"lng":123.4}`))
		request.Header.Set("Idempotency-Key", "telemetry-key")
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != http.StatusAccepted {
			t.Fatalf("request %d status = %d, want %d", index+1, response.Code, http.StatusAccepted)
		}
	}
	if calls.Load() != 2 {
		t.Fatalf("telemetry handler calls = %d, want 2", calls.Load())
	}
}

func TestIdempotencySkipsQueriesSensitiveAuthAndPresenceUpdates(t *testing.T) {
	for _, test := range []struct {
		name string
		path string
	}{
		{name: "authentication", path: "/api/v1/auth/login"},
		{name: "location query", path: "/api/v1/location/route"},
		{name: "fare query", path: "/api/v1/fares/estimate"},
		{name: "document upload", path: "/api/v1/driver/documents"},
		{name: "online presence", path: "/api/v1/drivers/12/online"},
	} {
		t.Run(test.name, func(t *testing.T) {
			var calls atomic.Int32
			handler := NewIdempotency(NewMemoryIdempotencyStore(), time.Minute).Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
				calls.Add(1)
				writer.WriteHeader(http.StatusOK)
			}))
			for index := 0; index < 2; index++ {
				request := httptest.NewRequest(http.MethodPost, test.path, strings.NewReader(`{"value":true}`))
				request.Header.Set("Idempotency-Key", "excluded-request-key")
				handler.ServeHTTP(httptest.NewRecorder(), request)
			}
			if calls.Load() != 2 {
				t.Fatalf("handler calls = %d, want 2", calls.Load())
			}
		})
	}
}

func TestIdempotencyScopesKeysToAuthorizationAndQuery(t *testing.T) {
	var calls atomic.Int32
	handler := NewIdempotency(NewMemoryIdempotencyStore(), time.Minute).Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		writer.WriteHeader(http.StatusCreated)
	}))

	for _, token := range []string{"Bearer first", "Bearer second"} {
		request := httptest.NewRequest(http.MethodPost, "/api/v1/rides?mode=direct", strings.NewReader(`{"fare_centavos":100}`))
		request.Header.Set("Authorization", token)
		request.Header.Set("Idempotency-Key", "scoped-key")
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != http.StatusCreated {
			t.Fatalf("token %q status = %d, want %d", token, response.Code, http.StatusCreated)
		}
	}
	if calls.Load() != 2 {
		t.Fatalf("scoped handler calls = %d, want 2", calls.Load())
	}
}
