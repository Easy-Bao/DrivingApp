package http

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
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

	for attempt := 0; attempt < 5; attempt++ {
		response := serveOTPVerificationAttempt(handler, "passenger@example.test", "192.0.2.10:1234")
		if response.Code != http.StatusNoContent {
			t.Fatalf("attempt %d status = %d, want %d", attempt+1, response.Code, http.StatusNoContent)
		}
	}

	blocked := serveOTPVerificationAttempt(handler, "passenger@example.test", "192.0.2.10:1234")
	if blocked.Code != http.StatusTooManyRequests {
		t.Fatalf("blocked status = %d, want %d", blocked.Code, http.StatusTooManyRequests)
	}

	// Another IP is not blocked, even for the same target email
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
