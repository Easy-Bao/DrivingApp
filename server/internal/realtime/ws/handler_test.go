package ws

import (
	"net/http/httptest"
	"testing"
)

func TestChatWebSocketOriginPolicy(t *testing.T) {
	handler := NewHandler(NewHub(), nil).WithAllowedOrigins([]string{"https://app.example"})

	nativeRequest := httptest.NewRequest("GET", "/api/v1/chat/ws", nil)
	if !handler.originAllowed(nativeRequest) {
		t.Fatal("native client without an Origin header was rejected")
	}

	allowedRequest := httptest.NewRequest("GET", "/api/v1/chat/ws", nil)
	allowedRequest.Header.Set("Origin", "https://app.example")
	if !handler.originAllowed(allowedRequest) {
		t.Fatal("configured browser origin was rejected")
	}

	untrustedRequest := httptest.NewRequest("GET", "/api/v1/chat/ws", nil)
	untrustedRequest.Header.Set("Origin", "https://untrusted.example")
	if handler.originAllowed(untrustedRequest) {
		t.Fatal("untrusted browser origin was accepted")
	}
}
