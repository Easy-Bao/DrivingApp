package http

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

func TestRouterOptionConfiguresOTPVerificationLimit(t *testing.T) {
	router := NewRouter(
		RouterDependencies{},
		WithOTPAttemptStore(middleware.NewMemoryCounterStore()),
	)
	if router.otpVerificationLimit == nil {
		t.Fatal("OTP verification rate limiter was not configured")
	}
}

func TestOTPVerificationRateLimiterThrottlesByIP(t *testing.T) {
	limiter := NewOTPVerificationRateLimiter(middleware.NewMemoryCounterStore())
	handler := limiter.Middleware(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))

	for attempt := range 5 {
		response := serveOTPVerificationAttempt(handler, "passenger@example.test", "192.0.2.10:1234")
		if response.Code != http.StatusNoContent {
			t.Fatalf("attempt %d status = %d, want %d", attempt+1, response.Code, http.StatusNoContent)
		}
		if limit := response.Header().Get("X-RateLimit-Limit"); limit != "5" {
			t.Fatalf("attempt %d limit = %q, want 5", attempt+1, limit)
		}
	}

	blocked := serveOTPVerificationAttempt(handler, "passenger@example.test", "192.0.2.10:1234")
	if blocked.Code != http.StatusTooManyRequests {
		t.Fatalf("blocked status = %d, want %d", blocked.Code, http.StatusTooManyRequests)
	}
	if remaining := blocked.Header().Get("X-RateLimit-Remaining"); remaining != "0" {
		t.Fatalf("blocked remaining = %q, want 0", remaining)
	}
	if retryAfter := blocked.Header().Get("Retry-After"); retryAfter != "900" {
		t.Fatalf("blocked retry-after = %q, want 900", retryAfter)
	}

	otherIP := serveOTPVerificationAttempt(handler, "passenger@example.test", "192.0.2.11:1234")
	if otherIP.Code != http.StatusNoContent {
		t.Fatalf("other IP status = %d, want %d", otherIP.Code, http.StatusNoContent)
	}
}

func serveOTPVerificationAttempt(handler http.Handler, email, remoteAddr string) *httptest.ResponseRecorder {
	body := strings.NewReader(`{"email":"` + email + `","code":"000000"}`)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/passenger/verify-otp", body)
	request.RemoteAddr = remoteAddr
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	return response
}

func TestOTPVerificationRateLimiterGroupsIPv6ByPrefix64(t *testing.T) {
	limiter := NewOTPVerificationRateLimiter(middleware.NewMemoryCounterStore())
	handler := limiter.Middleware(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))

	addrs := []string{
		"[2001:db8:abcd:0012::1]:1234",
		"[2001:db8:abcd:0012::2]:1235",
		"[2001:db8:abcd:0012::3]:1236",
		"[2001:db8:abcd:0012::4]:1237",
		"[2001:db8:abcd:0012::5]:1238",
	}
	for index, addr := range addrs {
		resp := serveOTPVerificationAttempt(handler, "passenger@example.test", addr)
		if resp.Code != http.StatusNoContent {
			t.Fatalf("attempt %d status = %d, want %d", index+1, resp.Code, http.StatusNoContent)
		}
	}

	blocked := serveOTPVerificationAttempt(handler, "passenger@example.test", "[2001:db8:abcd:0012::ff]:1239")
	if blocked.Code != http.StatusTooManyRequests {
		t.Fatalf("same /64 status = %d, want %d", blocked.Code, http.StatusTooManyRequests)
	}

	otherSubnet := serveOTPVerificationAttempt(handler, "passenger@example.test", "[2001:db8:abcd:0013::1]:1240")
	if otherSubnet.Code != http.StatusNoContent {
		t.Fatalf("different /64 status = %d, want %d", otherSubnet.Code, http.StatusNoContent)
	}
}

func TestOTPVerificationRateLimiterScopesAuthenticatedRequestsByUser(t *testing.T) {
	tokenManager := security.NewTokenManager("test-secret-for-otp-rate-limiter-32-bytes")
	user1Token, err := tokenManager.IssueWithRole("101", "passenger")
	if err != nil {
		t.Fatalf("IssueWithRole(101) error = %v", err)
	}
	user2Token, err := tokenManager.IssueWithRole("202", "passenger")
	if err != nil {
		t.Fatalf("IssueWithRole(202) error = %v", err)
	}

	limiter := NewOTPVerificationRateLimiter(middleware.NewMemoryCounterStore())
	handler := middleware.RequireAuth(tokenManager)(limiter.Middleware(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	})))

	serveAuthed := func(token, remoteAddr string) *httptest.ResponseRecorder {
		request := httptest.NewRequest(
			http.MethodPost,
			"/api/v1/users/me/email/confirm",
			strings.NewReader(`{"email":"new@example.test","code":"000000"}`),
		)
		request.RemoteAddr = remoteAddr
		request.Header.Set("Authorization", "Bearer "+token)
		request.Header.Set("Content-Type", "application/json")
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, request)
		return recorder
	}

	for attempt := range 5 {
		remoteAddr := "192.0.2." + string(rune('1'+attempt)) + ":1234"
		resp := serveAuthed(user1Token, remoteAddr)
		if resp.Code != http.StatusNoContent {
			t.Fatalf("user 101 attempt %d status = %d, want %d", attempt+1, resp.Code, http.StatusNoContent)
		}
	}

	// Same user from a different IP is still throttled under the user scope.
	blocked := serveAuthed(user1Token, "198.51.100.9:4321")
	if blocked.Code != http.StatusTooManyRequests {
		t.Fatalf("user 101 from new IP status = %d, want %d", blocked.Code, http.StatusTooManyRequests)
	}

	// Different authenticated user from the same IP gets their own bucket.
	otherUser := serveAuthed(user2Token, "198.51.100.9:4321")
	if otherUser.Code != http.StatusNoContent {
		t.Fatalf("user 202 status = %d, want %d", otherUser.Code, http.StatusNoContent)
	}
}
