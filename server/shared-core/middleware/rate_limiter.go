package middleware

import (
	"context"
	"fmt"
	"net"
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
	store       CounterStore
	globalLimit int64
	authLimit   int64
	window      time.Duration
}

func NewRateLimiter(store CounterStore, globalLimit, authLimit int64, window time.Duration) *RateLimiter {
	if globalLimit <= 0 {
		globalLimit = 120
	}
	if authLimit <= 0 {
		authLimit = 10
	}
	if window <= 0 {
		window = time.Minute
	}
	return &RateLimiter{store: store, globalLimit: globalLimit, authLimit: authLimit, window: window}
}

func NewRateLimiterFromEnv(store CounterStore) *RateLimiter {
	return NewRateLimiter(
		store,
		positiveInt64EnvValue("RATE_LIMIT_REQUESTS_PER_MINUTE", 120),
		positiveInt64EnvValue("AUTH_RATE_LIMIT_REQUESTS_PER_MINUTE", 10),
		time.Minute,
	)
}

func (limiter *RateLimiter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if limiter == nil || limiter.store == nil {
			next.ServeHTTP(writer, request)
			return
		}

		scope, limit := limiter.scopeAndLimit(request.URL.Path)
		key := fmt.Sprintf("rate:%s:%s:%d", scope, clientIP(request), windowKey(time.Now(), limiter.window))
		count, err := limiter.store.Increment(request.Context(), key, limiter.window)
		if err != nil {
			writer.Header().Set("Retry-After", "1")
			writeSecurityError(writer, http.StatusServiceUnavailable, "request protection is temporarily unavailable")
			return
		}
		writer.Header().Set("X-RateLimit-Limit", strconv.FormatInt(limit, 10))
		writer.Header().Set("X-RateLimit-Remaining", strconv.FormatInt(maxInt64(0, limit-count), 10))
		if count > limit {
			writer.Header().Set("Retry-After", strconv.FormatInt(int64(limiter.window/time.Second), 10))
			writeSecurityError(writer, http.StatusTooManyRequests, "too many requests")
			return
		}
		next.ServeHTTP(writer, request)
	})
}

func (limiter *RateLimiter) scopeAndLimit(path string) (string, int64) {
	if strings.Contains(path, "/auth/") {
		return "auth", limiter.authLimit
	}
	return "global", limiter.globalLimit
}

func clientIP(request *http.Request) string {
	if forwarded := request.Header.Get("X-Forwarded-For"); forwarded != "" {
		if first := strings.TrimSpace(strings.Split(forwarded, ",")[0]); first != "" {
			return first
		}
	}
	host, _, err := net.SplitHostPort(strings.TrimSpace(request.RemoteAddr))
	if err == nil && host != "" {
		return host
	}
	if request.RemoteAddr != "" {
		return request.RemoteAddr
	}
	return "unknown"
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
