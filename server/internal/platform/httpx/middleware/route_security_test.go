package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
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

	chain := security.Authenticated(RouteCommand, auth)
	var handler http.Handler = endpoint
	for i := len(chain) - 1; i >= 0; i-- {
		handler = chain[i](handler)
	}

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

	chain := security.Authenticated(RouteCommand, auth)
	var handler http.Handler = endpoint
	for i := len(chain) - 1; i >= 0; i-- {
		handler = chain[i](handler)
	}

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
