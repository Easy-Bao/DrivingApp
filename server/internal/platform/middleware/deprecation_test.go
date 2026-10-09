package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestDeprecationPreservesQueryAndResponse(t *testing.T) {
	called := false
	handler := Deprecation("/api/v1/drivers/me/documents")(
		http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			called = true
			writer.WriteHeader(http.StatusCreated)
			_, _ = writer.Write([]byte("created"))
		}),
	)
	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/driver/documents?type=driver_license",
		http.NoBody,
	)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if !called || response.Code != http.StatusCreated || response.Body.String() != "created" {
		t.Fatalf("handler response = %d %q, called = %t", response.Code, response.Body.String(), called)
	}
	if response.Header().Get("Deprecation") != "true" {
		t.Fatalf("Deprecation = %q, want true", response.Header().Get("Deprecation"))
	}
	if got := response.Header().Get("Link"); got != "</api/v1/drivers/me/documents?type=driver_license>; rel=\"successor-version\"" {
		t.Fatalf("Link = %q", got)
	}
}

func TestDeprecationPrefixMapsLegacyResourcePath(t *testing.T) {
	handler := DeprecationPrefix(
		"/api/v1/driver/documents/",
		"/api/v1/drivers/me/documents/",
	)(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	request := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/driver/documents/17/content?download=true",
		nil,
	)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if got := response.Header().Get("Link"); got != "</api/v1/drivers/me/documents/17/content?download=true>; rel=\"successor-version\"" {
		t.Fatalf("Link = %q", got)
	}
}
