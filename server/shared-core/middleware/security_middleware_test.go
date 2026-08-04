package middleware

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestSecureHTTPAddsRequestIDAndSecurityHeaders(t *testing.T) {
	handler := SecureHTTP(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if RequestIDFromRequest(request) == "" {
			t.Error("request id was not added to the context")
		}
		writer.WriteHeader(http.StatusNoContent)
	}), SecurityConfig{AllowedOrigins: []string{"https://app.example"}}, nil)

	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNoContent)
	}
	if response.Header().Get("X-Request-ID") == "" {
		t.Error("response did not include request id")
	}
	if response.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Error("nosniff header was not set")
	}
}

func TestCORSRejectsUnknownOrigin(t *testing.T) {
	handler := CORS([]string{"https://app.example"})(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		t.Error("downstream handler should not run")
	}))
	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	request.Header.Set("Origin", "https://evil.example")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusForbidden)
	}
}

func TestRequestBodyLimitRejectsOversizedBody(t *testing.T) {
	handler := RequestBodyLimit(16, 32)(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))
	request := httptest.NewRequest(http.MethodPost, "/auth/login", strings.NewReader(strings.Repeat("x", 17)))
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != http.StatusRequestEntityTooLarge {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusRequestEntityTooLarge)
	}
}

func TestRejectControlCharactersRejectsRequestTarget(t *testing.T) {
	handler := RejectControlCharacters(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		t.Error("downstream handler should not run")
	}))
	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	request.URL.RawQuery = "value=\x00"
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusBadRequest)
	}
}
