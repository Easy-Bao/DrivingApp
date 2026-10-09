package middleware

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
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
