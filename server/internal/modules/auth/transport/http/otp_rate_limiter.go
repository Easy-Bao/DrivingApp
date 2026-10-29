package http

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
)

const (
	_otpVerificationWindow = 15 * time.Minute
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

		key := counterKey("ip", middleware.ClientIPFromRequest(request))
		count, err := limiter.store.Increment(
			request.Context(),
			key,
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

		if count > domain.MaxOTPVerificationAttempts {
			if count == domain.MaxOTPVerificationAttempts+1 {
				slog.WarnContext(
					request.Context(),
					"OTP verification attempts throttled",
					"scope",
					"ip",
					"attempt_count",
					count,
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

		next.ServeHTTP(writer, request)
	})
}

func counterKey(scope, value string) string {
	digest := sha256.Sum256([]byte(value))
	return "rate:otp-verify:" + scope + ":" + hex.EncodeToString(digest[:])
}
