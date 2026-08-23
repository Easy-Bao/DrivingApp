package middleware

import (
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestProxyTrustRejectsForwardedHeadersFromDirectClients(t *testing.T) {
	trust, err := NewProxyTrust("")
	if err != nil {
		t.Fatal(err)
	}
	var clientIP, scheme, forwardedFor string
	handler := trust.Middleware(http.HandlerFunc(func(_ http.ResponseWriter, request *http.Request) {
		clientIP = ClientIPFromRequest(request)
		scheme = RequestSchemeFromRequest(request)
		forwardedFor = request.Header.Get("X-Forwarded-For")
	}))

	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	request.TLS = &tls.ConnectionState{}
	request.RemoteAddr = "198.51.100.10:4321"
	request.Header.Set("Forwarded", "for=203.0.113.99;proto=http")
	request.Header.Set("X-Forwarded-For", "203.0.113.99")
	request.Header.Set("X-Forwarded-Proto", "http")
	handler.ServeHTTP(httptest.NewRecorder(), request)

	if clientIP != "198.51.100.10" || forwardedFor != clientIP {
		t.Fatalf("client IP = %q, normalized header = %q", clientIP, forwardedFor)
	}
	if scheme != "https" {
		t.Fatalf("request scheme = %q, want https", scheme)
	}
	if request.Header.Get("Forwarded") != "" {
		t.Fatal("untrusted Forwarded header was not removed")
	}
}

func TestProxyTrustUsesLastUntrustedAddressFromTrustedChain(t *testing.T) {
	trust, err := NewProxyTrust("10.0.0.0/8, 192.168.0.0/16")
	if err != nil {
		t.Fatal(err)
	}
	var clientIP, scheme string
	handler := trust.Middleware(http.HandlerFunc(func(_ http.ResponseWriter, request *http.Request) {
		clientIP = ClientIPFromRequest(request)
		scheme = RequestSchemeFromRequest(request)
	}))

	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	request.RemoteAddr = "10.0.0.8:4321"
	request.Header.Set("X-Forwarded-For", "203.0.113.15, 192.168.1.9")
	request.Header.Set("X-Forwarded-Proto", "http, https")
	handler.ServeHTTP(httptest.NewRecorder(), request)

	if clientIP != "203.0.113.15" {
		t.Fatalf("client IP = %q, want 203.0.113.15", clientIP)
	}
	if scheme != "https" {
		t.Fatalf("request scheme = %q, want https", scheme)
	}
}

func TestNewProxyTrustRejectsInvalidCIDR(t *testing.T) {
	if _, err := NewProxyTrust("not-a-network"); err == nil {
		t.Fatal("expected invalid trusted proxy CIDR to fail")
	}
}
