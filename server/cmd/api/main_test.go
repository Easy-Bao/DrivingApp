package main

import (
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSanitizeForwardedHeadersUsesConnectionSecurity(t *testing.T) {
	var forwardedFor, forwardedProto string
	handler := sanitizeForwardedHeaders(http.HandlerFunc(func(_ http.ResponseWriter, request *http.Request) {
		forwardedFor = request.Header.Get("X-Forwarded-For")
		forwardedProto = request.Header.Get("X-Forwarded-Proto")
	}))

	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	request.TLS = &tls.ConnectionState{}
	request.RemoteAddr = "198.51.100.10:4321"
	request.Header.Set("X-Forwarded-For", "203.0.113.99")
	request.Header.Set("X-Forwarded-Proto", "http")
	handler.ServeHTTP(httptest.NewRecorder(), request)

	if forwardedFor != "198.51.100.10" {
		t.Fatalf("forwarded client IP = %q, want connection IP", forwardedFor)
	}
	if forwardedProto != "https" {
		t.Fatalf("forwarded protocol = %q, want https", forwardedProto)
	}
}
