package http

import (
	"encoding/json"
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

func TestOTPVerificationRateLimiterSeparatesEmailAndIPBuckets(t *testing.T) {
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

	otherEmail := serveOTPVerificationAttempt(handler, "other@example.test", "192.0.2.10:1234")
	if otherEmail.Code != http.StatusTooManyRequests {
		t.Fatalf("other email status = %d, want shared IP bucket", otherEmail.Code)
	}

	otherIP := serveOTPVerificationAttempt(handler, "new@example.test", "192.0.2.11:1234")
	if otherIP.Code != http.StatusNoContent {
		t.Fatalf("other IP status = %d, want independent bucket", otherIP.Code)
	}
}

func TestOTPVerificationRateLimiterRestoresRequestBody(t *testing.T) {
	limiter := NewOTPVerificationRateLimiter(middleware.NewMemoryCounterStore())
	var received map[string]string
	handler := limiter.Middleware(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if err := json.NewDecoder(request.Body).Decode(&received); err != nil {
			t.Fatalf("decode restored body: %v", err)
		}
		writer.WriteHeader(http.StatusNoContent)
	}))

	response := serveOTPVerificationAttempt(handler, "passenger@example.test", "192.0.2.12:1234")
	if response.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNoContent)
	}
	if received["email"] != "passenger@example.test" {
		t.Fatalf("restored email = %q", received["email"])
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

func TestOTPVerificationRateLimiterRejectsOversizeBody(t *testing.T) {
	limiter := NewOTPVerificationRateLimiter(middleware.NewMemoryCounterStore())
	handler := limiter.Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))

	oversize := strings.Repeat(" ", int(_otpVerificationBodyLimit)+10)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/passenger/verify-otp", strings.NewReader(oversize))
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusBadRequest {
		t.Fatalf("oversize status = %d, want %d", response.Code, http.StatusBadRequest)
	}
}

func TestOTPVerificationRateLimiterThrottlesMalformedJSONByIP(t *testing.T) {
	limiter := NewOTPVerificationRateLimiter(middleware.NewMemoryCounterStore())
	handler := limiter.Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))

	for attempt := 0; attempt < 5; attempt++ {
		request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/passenger/verify-otp", strings.NewReader(`{invalid-json`))
		request.RemoteAddr = "192.0.2.99:1234"
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != http.StatusNoContent {
			t.Fatalf("attempt %d status = %d, want %d", attempt+1, response.Code, http.StatusNoContent)
		}
	}

	// 6th attempt from same IP with malformed JSON must be throttled
	request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/passenger/verify-otp", strings.NewReader(`{invalid-json`))
	request.RemoteAddr = "192.0.2.99:1234"
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusTooManyRequests {
		t.Fatalf("throttled status = %d, want %d", response.Code, http.StatusTooManyRequests)
	}
}
