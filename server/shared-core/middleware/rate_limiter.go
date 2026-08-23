package middleware

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
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

const atomicIncrementScript = `
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
	return store.client.Eval(ctx, atomicIncrementScript, []string{key}, window.Milliseconds()).Int64()
}

type MemoryCounterStore struct {
	mu      sync.Mutex
	entries map[string]memoryCounter
}

type memoryCounter struct {
	count   int64
	expires time.Time
}

func NewMemoryCounterStore() *MemoryCounterStore {
	return &MemoryCounterStore{entries: make(map[string]memoryCounter)}
}

func (store *MemoryCounterStore) Increment(_ context.Context, key string, window time.Duration) (int64, error) {
	store.mu.Lock()
	defer store.mu.Unlock()
	now := time.Now()
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

type RateLimitConfig struct {
	Authentication int64
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
		Location:       60,
		Fare:           30,
		Connection:     30,
		Telemetry:      600,
		Mutation:       120,
		Read:           300,
		Window:         time.Minute,
	}
}

func NewRateLimiter(store CounterStore, config RateLimitConfig) *RateLimiter {
	return &RateLimiter{store: store, config: normalizedRateLimitConfig(config)}
}

func NewRateLimiterFromEnv(store CounterStore) *RateLimiter {
	defaults := DefaultRateLimitConfig()
	return NewRateLimiter(store, RateLimitConfig{
		Authentication: positiveInt64EnvValue("AUTH_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Authentication),
		Location:       positiveInt64EnvValue("LOCATION_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Location),
		Fare:           positiveInt64EnvValue("FARE_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Fare),
		Connection:     positiveInt64EnvValue("CONNECTION_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Connection),
		Telemetry:      positiveInt64EnvValue("TELEMETRY_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Telemetry),
		Mutation:       positiveInt64EnvValue("MUTATION_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Mutation),
		Read:           positiveInt64EnvValue("READ_RATE_LIMIT_REQUESTS_PER_MINUTE", defaults.Read),
		Window:         time.Minute,
	})
}

func (limiter *RateLimiter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if limiter == nil || limiter.store == nil {
			next.ServeHTTP(writer, request)
			return
		}

		policy, enabled := limiter.policy(request)
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
			writer.Header().Set("Retry-After", strconv.FormatInt(int64(limiter.config.Window/time.Second), 10))
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

func (limiter *RateLimiter) policy(request *http.Request) (rateLimitPolicy, bool) {
	if request.Method == http.MethodOptions {
		return rateLimitPolicy{}, false
	}
	switch classifyEndpoint(request) {
	case endpointHealth:
		return rateLimitPolicy{}, false
	case endpointAuthentication:
		return rateLimitPolicy{scope: "authentication", limit: limiter.config.Authentication, failClosed: true}, true
	case endpointLocationQuery:
		return rateLimitPolicy{scope: "location", limit: limiter.config.Location, failClosed: true}, true
	case endpointFareQuery:
		return rateLimitPolicy{scope: "fare", limit: limiter.config.Fare, failClosed: true}, true
	case endpointRealtimeConnection:
		return rateLimitPolicy{scope: "connection", limit: limiter.config.Connection, failClosed: true}, true
	case endpointTelemetry:
		return rateLimitPolicy{scope: "telemetry", limit: limiter.config.Telemetry}, true
	case endpointCommand, endpointDocumentUpload, endpointOnlinePresence:
		return rateLimitPolicy{scope: "mutation", limit: limiter.config.Mutation}, true
	default:
		return rateLimitPolicy{scope: "read", limit: limiter.config.Read}, true
	}
}

func normalizedRateLimitConfig(config RateLimitConfig) RateLimitConfig {
	defaults := DefaultRateLimitConfig()
	if config.Authentication <= 0 {
		config.Authentication = defaults.Authentication
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
	windowSeconds := int64(window / time.Second)
	if windowSeconds <= 0 {
		windowSeconds = 1
	}
	return now.Unix() / windowSeconds
}

func maxInt64(left, right int64) int64 {
	if left > right {
		return left
	}
	return right
}

func positiveInt64EnvValue(key string, fallback int64) int64 {
	value, err := strconv.ParseInt(strings.TrimSpace(os.Getenv(key)), 10, 64)
	if err != nil || value <= 0 {
		return fallback
	}
	return value
}
