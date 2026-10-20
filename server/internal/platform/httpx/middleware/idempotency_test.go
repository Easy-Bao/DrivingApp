package middleware

import (
	"bytes"
	"context"
	"encoding/json"
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
func (failingIdempotencyStore) DeleteIfValue(context.Context, string, []byte) error { return nil }

func newTestIdempotency(
	store IdempotencyStore,
	options ...IdempotencyOption,
) *Idempotency {
	return NewIdempotency(IdempotencyDependencies{Store: store}, options...)
}

func TestIdempotencyUsesDefaultExpirationForInvalidOption(t *testing.T) {
	idempotency := newTestIdempotency(nil, WithIdempotencyExpiration(0))
	if idempotency.expiration != _defaultIdempotencyExpiration {
		t.Fatalf("expiration = %s, want %s", idempotency.expiration, _defaultIdempotencyExpiration)
	}
}

func TestMemoryIdempotencyStoreOnlyReleasesTheCurrentLockOwner(t *testing.T) {
	store := NewMemoryIdempotencyStore()
	if err := store.Set(context.Background(), "lock", []byte("new-owner"), time.Minute); err != nil {
		t.Fatal(err)
	}

	if err := store.DeleteIfValue(context.Background(), "lock", []byte("old-owner")); err != nil {
		t.Fatal(err)
	}
	value, err := store.Get(context.Background(), "lock")
	if err != nil {
		t.Fatal(err)
	}
	if string(value) != "new-owner" {
		t.Fatalf("lock value = %q, want current owner to remain", value)
	}
}

func TestIdempotencyReplaysSuccessfulResponse(t *testing.T) {
	var calls atomic.Int32
	idempotency := newTestIdempotency(
		NewMemoryIdempotencyStore(),
		WithIdempotencyExpiration(time.Minute),
	)
	security := NewRouteSecurity(RouteSecurityDependencies{Idempotency: idempotency})
	handler := security.Middleware(RouteCommand)(
		http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			calls.Add(1)
			writer.Header().Set("Content-Type", "application/json")
			writer.WriteHeader(http.StatusCreated)
			_, _ = writer.Write([]byte(`{"created":true}`))
		}),
	)

	for index := 0; index < 2; index++ {
		request := httptest.NewRequest(
			http.MethodPost,
			"/api/v1/rides",
			strings.NewReader(`{"fare_amount":100}`),
		)
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
	handler := newTestIdempotency(store, WithIdempotencyExpiration(time.Minute)).Middleware(
		http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			writer.WriteHeader(http.StatusCreated)
		}),
	)

	first := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_amount":100}`))
	first.Header.Set("Idempotency-Key", "ride-key-2")
	handler.ServeHTTP(httptest.NewRecorder(), first)

	second := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_amount":200}`))
	second.Header.Set("Idempotency-Key", "ride-key-2")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, second)
	if response.Code != http.StatusConflict {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusConflict)
	}
}

func TestIdempotencyFailsClosedWhenStoreIsUnavailable(t *testing.T) {
	called := false
	handler := newTestIdempotency(
		failingIdempotencyStore{},
		WithIdempotencyExpiration(time.Minute),
	).Middleware(
		http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
			called = true
		}),
	)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_amount":100}`))
	request.Header.Set("Idempotency-Key", "ride-key-3")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusServiceUnavailable || called {
		t.Fatalf("status = %d, handler called = %t", response.Code, called)
	}
}

func TestIdempotencySkipsHighThroughputTelemetryUpdates(t *testing.T) {
	var calls atomic.Int32
	idempotency := newTestIdempotency(
		NewMemoryIdempotencyStore(),
		WithIdempotencyExpiration(time.Minute),
	)
	security := NewRouteSecurity(RouteSecurityDependencies{Idempotency: idempotency})
	handler := security.Middleware(RouteTelemetry)(
		http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			calls.Add(1)
			writer.WriteHeader(http.StatusAccepted)
		}),
	)

	for index := 0; index < 2; index++ {
		request := httptest.NewRequest(
			http.MethodPost,
			"/api/v1/telemetry/location",
			strings.NewReader(`{"lat":7.8,"lng":123.4}`),
		)
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

func TestRoutePoliciesExcludeNonCommandRequestsFromIdempotency(t *testing.T) {
	for _, test := range []struct {
		name   string
		policy RoutePolicy
		method string
	}{
		{name: "authentication", policy: RouteAuthentication, method: http.MethodPost},
		{name: "location query", policy: RouteLocationQuery, method: http.MethodPost},
		{name: "fare query", policy: RouteFareQuery, method: http.MethodPost},
		{name: "document upload", policy: RouteDocumentUpload, method: http.MethodPost},
		{name: "online presence", policy: RouteOnlinePresence, method: http.MethodPost},
	} {
		t.Run(test.name, func(t *testing.T) {
			var calls atomic.Int32
			idempotency := newTestIdempotency(
				NewMemoryIdempotencyStore(),
				WithIdempotencyExpiration(time.Minute),
			)
			security := NewRouteSecurity(RouteSecurityDependencies{Idempotency: idempotency})
			handler := security.Middleware(test.policy)(
				http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
					calls.Add(1)
					writer.WriteHeader(http.StatusOK)
				}),
			)
			for index := 0; index < 2; index++ {
				request := httptest.NewRequest(test.method, "/route", strings.NewReader(`{"value":true}`))
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
	handler := newTestIdempotency(
		NewMemoryIdempotencyStore(),
		WithIdempotencyExpiration(time.Minute),
	).Middleware(
		http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			calls.Add(1)
			writer.WriteHeader(http.StatusCreated)
		}),
	)

	for _, token := range []string{"Bearer first", "Bearer second"} {
		request := httptest.NewRequest(
			http.MethodPost,
			"/api/v1/rides?mode=direct",
			strings.NewReader(`{"fare_amount":100}`),
		)
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

func TestIdempotencyDoesNotCacheClientErrors(t *testing.T) {
	var calls atomic.Int32
	handler := newTestIdempotency(
		NewMemoryIdempotencyStore(),
		WithIdempotencyExpiration(time.Minute),
	).Middleware(
		http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			count := calls.Add(1)
			if count == 1 {
				writer.WriteHeader(http.StatusBadRequest)
				_, _ = writer.Write([]byte(`{"error":"bad request"}`))
				return
			}
			writer.WriteHeader(http.StatusOK)
			_, _ = writer.Write([]byte(`{"success":true}`))
		}),
	)

	request1 := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_amount":100}`))
	request1.Header.Set("Idempotency-Key", "retry-key-after-400")
	res1 := httptest.NewRecorder()
	handler.ServeHTTP(res1, request1)
	if res1.Code != http.StatusBadRequest {
		t.Fatalf("first request code = %d, want %d", res1.Code, http.StatusBadRequest)
	}

	request2 := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_amount":100}`))
	request2.Header.Set("Idempotency-Key", "retry-key-after-400")
	res2 := httptest.NewRecorder()
	handler.ServeHTTP(res2, request2)
	if res2.Code != http.StatusOK {
		t.Fatalf("second request code = %d, want %d", res2.Code, http.StatusOK)
	}
	if calls.Load() != 2 {
		t.Fatalf("expected 2 handler calls, got %d", calls.Load())
	}
}

func TestIdempotencyScopesKeysToPrincipalIdentity(t *testing.T) {
	var calls atomic.Int32
	handler := newTestIdempotency(
		NewMemoryIdempotencyStore(),
		WithIdempotencyExpiration(time.Minute),
	).Middleware(
		http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			calls.Add(1)
			writer.WriteHeader(http.StatusOK)
			_, _ = writer.Write([]byte(`{"ok":true}`))
		}),
	)

	ctx := context.WithValue(context.Background(), _principalKey, Principal{UserID: 42, Role: "passenger"})
	for _, token := range []string{"Bearer old-jwt", "Bearer refreshed-jwt"} {
		request := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare_amount":100}`))
		request = request.WithContext(ctx)
		request.Header.Set("Authorization", token)
		request.Header.Set("Idempotency-Key", "principal-scoped-key")
		res := httptest.NewRecorder()
		handler.ServeHTTP(res, request)
		if res.Code != http.StatusOK {
			t.Fatalf("status = %d, want %d", res.Code, http.StatusOK)
		}
	}
	if calls.Load() != 1 {
		t.Fatalf("expected 1 call (cached replay), got %d", calls.Load())
	}
}

type raceIdempotencyStore struct {
	IdempotencyStore
	onSetNX func(ctx context.Context, key string)
}

func (s *raceIdempotencyStore) SetNX(ctx context.Context, key string, value []byte, expiration time.Duration) (bool, error) {
	if s.onSetNX != nil {
		s.onSetNX(ctx, key)
	}
	return s.IdempotencyStore.SetNX(ctx, key, value, expiration)
}

func TestIdempotencyRechecksResultAfterLockAcquisition(t *testing.T) {
	memStore := NewMemoryIdempotencyStore()
	var calls atomic.Int32

	store := &raceIdempotencyStore{
		IdempotencyStore: memStore,
	}

	idempotency := newTestIdempotency(store, WithIdempotencyExpiration(time.Minute))
	security := NewRouteSecurity(RouteSecurityDependencies{Idempotency: idempotency})
	handler := security.Middleware(RouteCommand)(
		http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			calls.Add(1)
			writer.Header().Set("Content-Type", "application/json")
			writer.WriteHeader(http.StatusCreated)
			_, _ = writer.Write([]byte(`{"created":true}`))
		}),
	)

	requestBody := []byte(`{"fare_amount":100}`)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/rides", bytes.NewReader(requestBody))
	request.Header.Set("Idempotency-Key", "race-key-1")

	// Simulate request A having completed and stored its result just as request B
	// acquires the lock.
	store.onSetNX = func(ctx context.Context, key string) {
		resultKey := strings.TrimSuffix(key, ":lock") + ":result"
		record, _ := json.Marshal(idempotentResponse{
			Fingerprint: requestFingerprint(request, requestBody),
			Status:      http.StatusCreated,
			Headers:     map[string][]string{"Content-Type": {"application/json"}},
			Body:        []byte(`{"created":true}`),
		})
		_ = memStore.Set(ctx, resultKey, record, time.Minute)
	}

	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusCreated)
	}
	if calls.Load() != 0 {
		t.Fatalf("handler calls = %d, want 0 (replayed from rechecked result)", calls.Load())
	}
}
