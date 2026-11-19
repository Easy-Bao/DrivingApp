package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"slices"
	"strings"
	"testing"
	"time"
)

func TestRouteSecurityLimitsBodiesBeforeAuthentication(t *testing.T) {
	security := NewRouteSecurity(RouteSecurityDependencies{
		Config: SecurityConfig{JSONBodyLimit: 16, UploadBodyLimit: 32},
	})
	authentication := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			writer.WriteHeader(http.StatusUnauthorized)
		})
	}
	handler := security.Middleware(RouteCommand)(authentication(http.HandlerFunc(func(
		http.ResponseWriter,
		*http.Request,
	) {
	})))
	request := httptest.NewRequest(
		http.MethodPost,
		"/route",
		strings.NewReader(strings.Repeat("x", 17)),
	)
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != http.StatusRequestEntityTooLarge {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusRequestEntityTooLarge)
	}
}

func TestRouteSecurityUsesUploadLimitForDocumentRoutes(t *testing.T) {
	security := NewRouteSecurity(RouteSecurityDependencies{
		Config: SecurityConfig{JSONBodyLimit: 16, UploadBodyLimit: 32},
	})
	handler := security.Middleware(RouteDocumentUpload)(http.HandlerFunc(func(
		writer http.ResponseWriter,
		request *http.Request,
	) {
		if _, err := request.Body.Read(make([]byte, 33)); err != nil {
			t.Errorf("read document body: %v", err)
		}
		writer.WriteHeader(http.StatusNoContent)
	}))
	request := httptest.NewRequest(http.MethodPost, "/route", strings.NewReader(strings.Repeat("x", 32)))
	request.Header.Set("Content-Type", "application/octet-stream")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNoContent)
	}
}

func TestRouteSecurityAuthenticatedChainScopesIdempotencyToPrincipal(t *testing.T) {
	idempotency := newTestIdempotency(
		NewMemoryIdempotencyStore(),
		WithIdempotencyExpiration(time.Minute),
	)
	security := NewRouteSecurity(RouteSecurityDependencies{Idempotency: idempotency})

	auth := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			token := request.Header.Get("Authorization")
			if token == "Bearer token-1" || token == "Bearer token-2" {
				ctx := context.WithValue(request.Context(), _principalKey, Principal{UserID: 42, Role: "passenger"})
				next.ServeHTTP(writer, request.WithContext(ctx))
				return
			}
			writer.WriteHeader(http.StatusUnauthorized)
		})
	}

	var handlerCalls int
	endpoint := http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		handlerCalls++
		writer.WriteHeader(http.StatusCreated)
		_, _ = writer.Write([]byte(`{"created":true}`))
	})

	handler := applyMiddlewareChain(security.Authenticated(RouteCommand, auth), endpoint)

	req1 := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare":100}`))
	req1.Header.Set("Authorization", "Bearer token-1")
	req1.Header.Set("Idempotency-Key", "order-12345678")
	res1 := httptest.NewRecorder()
	handler.ServeHTTP(res1, req1)
	if res1.Code != http.StatusCreated {
		t.Fatalf("first request status = %d, want 201", res1.Code)
	}
	if handlerCalls != 1 {
		t.Fatalf("handler calls = %d, want 1", handlerCalls)
	}

	req2 := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare":100}`))
	req2.Header.Set("Authorization", "Bearer token-2")
	req2.Header.Set("Idempotency-Key", "order-12345678")
	res2 := httptest.NewRecorder()
	handler.ServeHTTP(res2, req2)
	if res2.Code != http.StatusCreated {
		t.Fatalf("second request status = %d, want 201", res2.Code)
	}
	if handlerCalls != 1 {
		t.Fatalf("handler calls after rotated token = %d, want 1 (replayed from cache)", handlerCalls)
	}
}

func TestRouteSecurityAuthenticatedChainRejectsExpiredTokenBeforeIdempotencyReplay(t *testing.T) {
	idempotency := newTestIdempotency(
		NewMemoryIdempotencyStore(),
		WithIdempotencyExpiration(time.Minute),
	)
	security := NewRouteSecurity(RouteSecurityDependencies{Idempotency: idempotency})

	validToken := true
	auth := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			if validToken {
				ctx := context.WithValue(request.Context(), _principalKey, Principal{UserID: 42, Role: "passenger"})
				next.ServeHTTP(writer, request.WithContext(ctx))
				return
			}
			writer.WriteHeader(http.StatusUnauthorized)
		})
	}

	endpoint := http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusCreated)
		_, _ = writer.Write([]byte(`{"created":true}`))
	})

	handler := applyMiddlewareChain(security.Authenticated(RouteCommand, auth), endpoint)

	req1 := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare":100}`))
	req1.Header.Set("Authorization", "Bearer valid-jwt")
	req1.Header.Set("Idempotency-Key", "order-12345678")
	res1 := httptest.NewRecorder()
	handler.ServeHTTP(res1, req1)
	if res1.Code != http.StatusCreated {
		t.Fatalf("first request status = %d, want 201", res1.Code)
	}

	validToken = false
	req2 := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare":100}`))
	req2.Header.Set("Authorization", "Bearer valid-jwt")
	req2.Header.Set("Idempotency-Key", "order-12345678")
	res2 := httptest.NewRecorder()
	handler.ServeHTTP(res2, req2)
	if res2.Code != http.StatusUnauthorized {
		t.Fatalf("expired token status = %d, want 401 Unauthorized", res2.Code)
	}
}

func applyMiddlewareChain(chain []func(http.Handler) http.Handler, endpoint http.Handler) http.Handler {
	handler := endpoint
	for _, wrap := range slices.Backward(chain) {
		handler = wrap(handler)
	}
	return handler
}

func TestRouteSecurityEnforcesRateLimitAndGuardsBeforeIdempotency(t *testing.T) {
	store := NewMemoryIdempotencyStore()
	idempotency := newTestIdempotency(store, WithIdempotencyExpiration(time.Minute))
	limitConfig := DefaultRateLimitConfig()
	limitConfig.Mutation = 1
	limiter := NewRateLimiter(RateLimiterDependencies{
		Store:  NewMemoryCounterStore(),
		Config: limitConfig,
	})
	security := NewRouteSecurity(RouteSecurityDependencies{
		Config:      SecurityConfig{JSONBodyLimit: 32, UploadBodyLimit: 1024},
		RateLimiter: limiter,
		Idempotency: idempotency,
	})

	// 1. Rate limiter must reject second request even with a cached Idempotency-Key.
	handler := security.Middleware(RouteCommand)(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusCreated)
	}))
	for i, want := range []int{http.StatusCreated, http.StatusTooManyRequests} {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(`{"fare":10}`))
		req.RemoteAddr = "192.0.2.50:1234"
		req.Header.Set("Idempotency-Key", "rate-before-idem-key")
		res := httptest.NewRecorder()
		handler.ServeHTTP(res, req)
		if res.Code != want {
			t.Fatalf("request %d status = %d, want %d", i+1, res.Code, want)
		}
	}

	// 2. Role guard must reject unauthorized role before idempotency touches the store.
	auth := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			ctx := context.WithValue(request.Context(), _principalKey, Principal{UserID: 7, Role: "passenger"})
			next.ServeHTTP(writer, request.WithContext(ctx))
		})
	}
	forbidGuard := func(http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			writer.WriteHeader(http.StatusForbidden)
		})
	}
	guardedSecurity := NewRouteSecurity(RouteSecurityDependencies{
		Config:      SecurityConfig{JSONBodyLimit: 32, UploadBodyLimit: 1024},
		Idempotency: newTestIdempotency(failingIdempotencyStore{}),
	})
	guarded := applyMiddlewareChain(
		guardedSecurity.Authenticated(RouteCommand, auth, forbidGuard),
		http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			writer.WriteHeader(http.StatusOK)
		}),
	)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/drivers/only", strings.NewReader(`{}`))
	req.Header.Set("Idempotency-Key", "guard-before-idem-key")
	res := httptest.NewRecorder()
	guarded.ServeHTTP(res, req)
	if res.Code != http.StatusForbidden {
		t.Fatalf("guarded status = %d, want 403 (idempotency should not run before role guard)", res.Code)
	}

	// 3. Spoofed multipart Content-Type on a JSON command route must still enforce JSONBodyLimit.
	spoofReq := httptest.NewRequest(http.MethodPost, "/api/v1/rides", strings.NewReader(strings.Repeat("a", 64)))
	spoofReq.Header.Set("Content-Type", "multipart/form-data; boundary=evil")
	spoofRes := httptest.NewRecorder()
	guardedSecurity.Middleware(RouteCommand)(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusOK)
	})).ServeHTTP(spoofRes, spoofReq)
	if spoofRes.Code != http.StatusRequestEntityTooLarge {
		t.Fatalf("spoofed multipart status = %d, want 413", spoofRes.Code)
	}
}
