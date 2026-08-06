package main

import (
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWithForwardedHeadersOverwritesClientSuppliedValues(t *testing.T) {
	var protocol, clientIP string
	handler := withForwardedHeaders(http.HandlerFunc(func(_ http.ResponseWriter, request *http.Request) {
		protocol = request.Header.Get("X-Forwarded-Proto")
		clientIP = request.Header.Get("X-Forwarded-For")
	}))
	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	request.RemoteAddr = "192.0.2.5:1234"
	request.TLS = &tls.ConnectionState{}
	request.Header.Set("X-Forwarded-Proto", "http")
	request.Header.Set("X-Forwarded-For", "203.0.113.99")
	handler.ServeHTTP(httptest.NewRecorder(), request)

	if protocol != "https" {
		t.Fatalf("forwarded protocol = %q, want https", protocol)
	}
	if clientIP != "192.0.2.5" {
		t.Fatalf("forwarded client IP = %q, want 192.0.2.5", clientIP)
	}
}
