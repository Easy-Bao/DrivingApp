package middleware

import (
	"fmt"
	"log/slog"
	"net/http"
	"strconv"
	"time"
)

type RateLimiter struct {
	store  CounterStore
	config RateLimitConfig
}

type RateLimiterDependencies struct {
	Store  CounterStore
	Config RateLimitConfig
}

type RateLimitConfig struct {
	Authentication int64
	Refresh        int64
	Location       int64
	Fare           int64
	Connection     int64
	Telemetry      int64
	Mutation       int64
	Read           int64
	Window         time.Duration
}

func DefaultRateLimitConfig() RateLimitConfig {
	return RateLimitConfig{
		Authentication: 10,
		Refresh:        10,
		Location:       60,
		Fare:           30,
		Connection:     30,
		Telemetry:      600,
		Mutation:       120,
		Read:           300,
		Window:         time.Minute,
	}
}

func NewRateLimiter(dependencies RateLimiterDependencies) *RateLimiter {
	return &RateLimiter{
		store:  dependencies.Store,
		config: normalizedRateLimitConfig(dependencies.Config),
	}
}

func (limiter *RateLimiter) Middleware(next http.Handler) http.Handler {
	return limiter.MiddlewareFor(RouteDefault)(next)
}

func (limiter *RateLimiter) MiddlewareFor(routePolicy RoutePolicy) func(http.Handler) http.Handler {
	if routePolicy == RouteDefault {
		return func(next http.Handler) http.Handler {
			readHandler := limiter.policyMiddleware(RouteRead, next)
			commandHandler := limiter.policyMiddleware(RouteCommand, next)
			return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
				if isStateChangingMethod(request.Method) {
					commandHandler.ServeHTTP(writer, request)
					return
				}
				readHandler.ServeHTTP(writer, request)
			})
		}
	}
	return func(next http.Handler) http.Handler {
		return limiter.policyMiddleware(routePolicy, next)
	}
}

func (limiter *RateLimiter) policyMiddleware(routePolicy RoutePolicy, next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if limiter == nil || limiter.store == nil {
			next.ServeHTTP(writer, request)
			return
		}

		if request.Method == http.MethodOptions {
			next.ServeHTTP(writer, request)
			return
		}
		policy, enabled := limiter.policy(routePolicy)
		if !enabled {
			next.ServeHTTP(writer, request)
			return
		}
		key := fmt.Sprintf(
			"rate:%s:%s:%d",
			policy.scope,
			RateLimitClientKey(ClientIPFromRequest(request)),
			windowKey(time.Now(), limiter.config.Window),
		)
		count, err := limiter.store.Increment(request.Context(), key, limiter.config.Window)
		if err != nil {
			if policy.failClosed {
				writeProtectionUnavailable(writer)
				return
			}
			slog.WarnContext(
				request.Context(),
				"rate limiter store failed open",
				"scope", policy.scope,
				"error", err,
			)
			next.ServeHTTP(writer, request)
			return
		}
		writer.Header().Set("X-RateLimit-Limit", strconv.FormatInt(policy.limit, 10))
		writer.Header().Set("X-RateLimit-Remaining", strconv.FormatInt(max(0, policy.limit-count), 10))
		if count > policy.limit {
			writer.Header().Set(
				"Retry-After",
				strconv.FormatInt(retryAfterSeconds(time.Now(), limiter.config.Window), 10),
			)
			writeSecurityError(writer, http.StatusTooManyRequests, "too many requests")
			return
		}
		next.ServeHTTP(writer, request)
	})
}

type rateLimitPolicy struct {
	scope      string
	limit      int64
	failClosed bool
}

func (limiter *RateLimiter) policy(routePolicy RoutePolicy) (rateLimitPolicy, bool) {
	switch routePolicy {
	case RouteHealth:
		return rateLimitPolicy{}, false
	case RouteAuthentication:
		return rateLimitPolicy{scope: "authentication", limit: limiter.config.Authentication, failClosed: true}, true
	case RouteRefresh:
		return rateLimitPolicy{scope: "refresh", limit: limiter.config.Refresh, failClosed: true}, true
	case RouteLocationQuery:
		return rateLimitPolicy{scope: "location", limit: limiter.config.Location, failClosed: true}, true
	case RouteFareQuery:
		return rateLimitPolicy{scope: "fare", limit: limiter.config.Fare, failClosed: true}, true
	case RouteRealtimeConnection:
		return rateLimitPolicy{scope: "connection", limit: limiter.config.Connection, failClosed: true}, true
	case RouteTelemetry:
		return rateLimitPolicy{scope: "telemetry", limit: limiter.config.Telemetry}, true
	case RouteCommand, RouteDocumentUpload, RouteOnlinePresence:
		return rateLimitPolicy{scope: "mutation", limit: limiter.config.Mutation}, true
	case RouteRead:
		return rateLimitPolicy{scope: "read", limit: limiter.config.Read}, true
	default:
		return rateLimitPolicy{}, false
	}
}

func normalizedRateLimitConfig(config RateLimitConfig) RateLimitConfig {
	defaults := DefaultRateLimitConfig()
	config.Authentication = positiveOrDefault(config.Authentication, defaults.Authentication)
	config.Refresh = positiveOrDefault(config.Refresh, defaults.Refresh)
	config.Location = positiveOrDefault(config.Location, defaults.Location)
	config.Fare = positiveOrDefault(config.Fare, defaults.Fare)
	config.Connection = positiveOrDefault(config.Connection, defaults.Connection)
	config.Telemetry = positiveOrDefault(config.Telemetry, defaults.Telemetry)
	config.Mutation = positiveOrDefault(config.Mutation, defaults.Mutation)
	config.Read = positiveOrDefault(config.Read, defaults.Read)
	config.Window = positiveOrDefault(config.Window, defaults.Window)
	return config
}

func positiveOrDefault[T ~int64](value, fallback T) T {
	if value <= 0 {
		return fallback
	}
	return value
}

func windowKey(now time.Time, window time.Duration) int64 {
	windowNanoseconds := window.Nanoseconds()
	if windowNanoseconds <= 0 {
		windowNanoseconds = time.Second.Nanoseconds()
	}
	return now.UnixNano() / windowNanoseconds
}

func retryAfterSeconds(now time.Time, window time.Duration) int64 {
	windowNanoseconds := window.Nanoseconds()
	if windowNanoseconds <= 0 {
		return 1
	}
	remainingNanoseconds := windowNanoseconds - now.UnixNano()%windowNanoseconds
	seconds := remainingNanoseconds / time.Second.Nanoseconds()
	if remainingNanoseconds%time.Second.Nanoseconds() != 0 {
		seconds++
	}
	return max(1, seconds)
}

// RateLimitClientKey normalizes a client IP for rate limiting, masking IPv6
// addresses to their /64 prefix so a single allocation cannot rotate host bits.
func RateLimitClientKey(clientIP string) string {
	address, ok := parseRequestAddress(clientIP)
	if !ok {
		return clientIP
	}
	address = address.Unmap()
	if address.Is6() {
		prefix, err := address.Prefix(64)
		if err == nil {
			return prefix.Masked().String()
		}
	}
	return address.String()
}
