package middleware

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"sync"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

type CounterStore interface {
	Increment(ctx context.Context, key string, window time.Duration) (int64, error)
}

type RedisCounterStore struct {
	client *redisclient.Client
}

var _ CounterStore = (*RedisCounterStore)(nil)

const _atomicIncrementScript = `
local count = redis.call('INCR', KEYS[1])
if count == 1 then
  redis.call('PEXPIRE', KEYS[1], ARGV[1])
end
return count
`

func NewRedisCounterStore(client *redisclient.Client) *RedisCounterStore {
	return &RedisCounterStore{client: client}
}

func (store *RedisCounterStore) Increment(ctx context.Context, key string, window time.Duration) (int64, error) {
	if store == nil || store.client == nil {
		return 0, fmt.Errorf("redis counter store is not configured")
	}
	if ctx == nil {
		return 0, errors.New("counter context is nil")
	}
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	if window <= 0 {
		return 0, errors.New("counter window must be positive")
	}
	expirationMilliseconds := window.Milliseconds()
	if expirationMilliseconds <= 0 {
		expirationMilliseconds = 1
	}
	count, err := store.client.Eval(
		ctx,
		_atomicIncrementScript,
		[]string{key},
		expirationMilliseconds,
	).Int64()
	if err != nil {
		return 0, fmt.Errorf("increment redis rate-limit counter: %w", err)
	}
	return count, nil
}

type MemoryCounterStore struct {
	mu         sync.Mutex
	entries    map[string]memoryCounter
	operations uint64
}

var _ CounterStore = (*MemoryCounterStore)(nil)

type memoryCounter struct {
	count   int64
	expires time.Time
}

const _memoryCounterCleanupInterval = 128

func NewMemoryCounterStore() *MemoryCounterStore {
	return &MemoryCounterStore{entries: make(map[string]memoryCounter)}
}

func (store *MemoryCounterStore) Increment(ctx context.Context, key string, window time.Duration) (int64, error) {
	if store == nil {
		return 0, errors.New("memory counter store is not configured")
	}
	if ctx == nil {
		return 0, errors.New("counter context is nil")
	}
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	if window <= 0 {
		return 0, errors.New("counter window must be positive")
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.entries == nil {
		store.entries = make(map[string]memoryCounter)
	}
	now := time.Now()
	store.operations++
	if store.operations%_memoryCounterCleanupInterval == 0 {
		for entryKey, entry := range store.entries {
			if !now.Before(entry.expires) {
				delete(store.entries, entryKey)
			}
		}
	}
	entry, ok := store.entries[key]
	if !ok || !now.Before(entry.expires) {
		entry = memoryCounter{expires: now.Add(window)}
	}
	entry.count++
	store.entries[key] = entry
	return entry.count, nil
}

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

func RateLimitConfigFrom(getenv func(string) string) RateLimitConfig {
	defaults := DefaultRateLimitConfig()
	return RateLimitConfig{
		Authentication: positiveInt64Value(getenv, "AUTH_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Authentication),
		Refresh:        positiveInt64Value(getenv, "REFRESH_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Refresh),
		Location:       positiveInt64Value(getenv, "LOCATION_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Location),
		Fare:           positiveInt64Value(getenv, "FARE_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Fare),
		Connection:     positiveInt64Value(getenv, "CONNECTION_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Connection),
		Telemetry:      positiveInt64Value(getenv, "TELEMETRY_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Telemetry),
		Mutation:       positiveInt64Value(getenv, "MUTATION_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Mutation),
		Read:           positiveInt64Value(getenv, "READ_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Read),
		Window:         time.Minute,
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
			ClientIPFromRequest(request),
			windowKey(time.Now(), limiter.config.Window),
		)
		count, err := limiter.store.Increment(request.Context(), key, limiter.config.Window)
		if err != nil {
			if policy.failClosed {
				writer.Header().Set("Retry-After", "1")
				writeSecurityError(writer, http.StatusServiceUnavailable, "request protection is temporarily unavailable")
				return
			}
			next.ServeHTTP(writer, request)
			return
		}
		writer.Header().Set("X-RateLimit-Limit", strconv.FormatInt(policy.limit, 10))
		writer.Header().Set("X-RateLimit-Remaining", strconv.FormatInt(maxInt64(0, policy.limit-count), 10))
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
	if config.Authentication <= 0 {
		config.Authentication = defaults.Authentication
	}
	if config.Refresh <= 0 {
		config.Refresh = defaults.Refresh
	}
	if config.Location <= 0 {
		config.Location = defaults.Location
	}
	if config.Fare <= 0 {
		config.Fare = defaults.Fare
	}
	if config.Connection <= 0 {
		config.Connection = defaults.Connection
	}
	if config.Telemetry <= 0 {
		config.Telemetry = defaults.Telemetry
	}
	if config.Mutation <= 0 {
		config.Mutation = defaults.Mutation
	}
	if config.Read <= 0 {
		config.Read = defaults.Read
	}
	if config.Window <= 0 {
		config.Window = defaults.Window
	}
	return config
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
	return maxInt64(1, seconds)
}

func maxInt64(left, right int64) int64 {
	if left > right {
		return left
	}
	return right
}
