package http

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

const (
	_otpVerificationWindow          = 15 * time.Minute
	_otpVerificationBodyLimit int64 = 16 << 10
)

type OTPVerificationRateLimiter struct {
	store middleware.CounterStore
}

type otpAttemptBucket struct {
	scope string
	key   string
	count int64
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

		body, err := io.ReadAll(io.LimitReader(request.Body, _otpVerificationBodyLimit))
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

		buckets := []otpAttemptBucket{{
			scope: "ip",
			key:   counterKey("ip", middleware.ClientIPFromRequest(request)),
		}}
		if email := strings.ToLower(strings.TrimSpace(input.Email)); email != "" {
			buckets = append(buckets, otpAttemptBucket{
				scope: "email",
				key:   counterKey("email", email),
			})
		}
		for index := range buckets {
			bucket := &buckets[index]
			count, err := limiter.store.Increment(
				request.Context(),
				bucket.key,
				_otpVerificationWindow,
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
			bucket.count = count
		}
		for _, bucket := range buckets {
			if bucket.count > domain.MaxOTPVerificationAttempts {
				if bucket.count == domain.MaxOTPVerificationAttempts+1 {
					slog.WarnContext(
						request.Context(),
						"OTP verification attempts throttled",
						"scope",
						bucket.scope,
						"attempt_count",
						bucket.count,
					)
				}
				writer.Header().Set("Retry-After", "900")
				writer.Header().Set(
					"X-RateLimit-Limit",
					fmt.Sprintf("%d", domain.MaxOTPVerificationAttempts),
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
