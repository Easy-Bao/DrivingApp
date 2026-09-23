package http

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

const (
	maxOTPVerificationAttempts int64 = 5
	otpVerificationWindow            = 15 * time.Minute
	otpVerificationBodyLimit   int64 = 16 << 10
)

type OTPVerificationRateLimiter struct {
	store middleware.CounterStore
}

func NewOTPVerificationRateLimiter(store middleware.CounterStore) *OTPVerificationRateLimiter {
	return &OTPVerificationRateLimiter{store: store}
}

func (limiter *OTPVerificationRateLimiter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if limiter == nil || limiter.store == nil {
			next.ServeHTTP(writer, request)
			return
		}

		body, err := io.ReadAll(io.LimitReader(request.Body, otpVerificationBodyLimit))
		if err != nil {
			next.ServeHTTP(writer, request)
			return
		}
		request.Body = io.NopCloser(bytes.NewReader(body))

		var input struct {
			Email string `json:"email"`
		}
		if err := json.Unmarshal(body, &input); err != nil {
			next.ServeHTTP(writer, request)
			return
		}

		keys := []string{counterKey("ip", middleware.ClientIPFromRequest(request))}
		if email := strings.ToLower(strings.TrimSpace(input.Email)); email != "" {
			keys = append(keys, counterKey("email", email))
		}
		for _, key := range keys {
			count, err := limiter.store.Increment(
				request.Context(),
				key,
				otpVerificationWindow,
			)
			if err != nil {
				writer.Header().Set("Retry-After", "1")
				response.Error(
					writer,
					http.StatusServiceUnavailable,
					"request protection is temporarily unavailable",
				)
				return
			}
			if count > maxOTPVerificationAttempts {
				writer.Header().Set("Retry-After", "900")
				writer.Header().Set(
					"X-RateLimit-Limit",
					fmt.Sprintf("%d", maxOTPVerificationAttempts),
				)
				response.Error(writer, http.StatusTooManyRequests, "too many verification attempts")
				return
			}
		}

		next.ServeHTTP(writer, request)
	})
}

func counterKey(scope, value string) string {
	digest := sha256.Sum256([]byte(value))
	return "rate:otp-verify:" + scope + ":" + hex.EncodeToString(digest[:])
}
