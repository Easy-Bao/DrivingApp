package redis

import (
	"context"
	"errors"
	"testing"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

type presenceKVStub struct {
	values map[string]string
	ttls   map[string]time.Duration
	getErr error
	setErr error
}

func (stub *presenceKVStub) Get(_ context.Context, key string) (string, error) {
	if stub.getErr != nil {
		return "", stub.getErr
	}
	val, ok := stub.values[key]
	if !ok {
		return "", redisclient.Nil
	}
	return val, nil
}

func (stub *presenceKVStub) Set(_ context.Context, key, value string, expiration time.Duration) error {
	if stub.setErr != nil {
		return stub.setErr
	}
	if stub.values == nil {
		stub.values = make(map[string]string)
	}
	if stub.ttls == nil {
		stub.ttls = make(map[string]time.Duration)
	}
	stub.values[key] = value
	stub.ttls[key] = expiration
	return nil
}

func TestDriverPresenceCacheAvoidsPostgresOnCacheHitAndUpdatesOnToggle(t *testing.T) {
	kv := &presenceKVStub{}
	pgCalls := 0
	pgOnline := true
	cache := newDriverPresenceCacheWithKV(kv, func(_ context.Context, userID int, _ time.Duration) (bool, error) {
		pgCalls++
		return pgOnline, nil
	}, 45*time.Second, nil)

	ctx := context.Background()
	cache.SetOnline(ctx, 42, true)
	if kv.ttls["driver:online:42"] != 45*time.Second {
		t.Fatalf("cache TTL = %v, want 45s", kv.ttls["driver:online:42"])
	}

	online, err := cache.IsOnline(ctx, "42")
	if err != nil || !online || pgCalls != 0 {
		t.Fatalf("IsOnline hit = (%v, %v, pgCalls=%d), want (true, nil, 0)", online, err, pgCalls)
	}

	cache.SetOnline(ctx, 42, false)
	online, err = cache.IsOnline(ctx, "42")
	if err != nil || online || pgCalls != 0 {
		t.Fatalf("IsOnline offline hit = (%v, %v, pgCalls=%d), want (false, nil, 0)", online, err, pgCalls)
	}
}

func TestDriverPresenceCacheFallsBackToPostgresOnMissAndRedisFailure(t *testing.T) {
	kv := &presenceKVStub{}
	pgCalls := 0
	cache := newDriverPresenceCacheWithKV(kv, func(_ context.Context, _ int, _ time.Duration) (bool, error) {
		pgCalls++
		return true, nil
	}, 45*time.Second, nil)

	ctx := context.Background()
	online, err := cache.IsOnline(ctx, "7")
	if err != nil || !online || pgCalls != 1 {
		t.Fatalf("miss fallback = (%v, %v, pgCalls=%d), want (true, nil, 1)", online, err, pgCalls)
	}
	if kv.values["driver:online:7"] != "1" || kv.ttls["driver:online:7"] != _fallbackPresenceTTL {
		t.Fatalf("populated cache = val:%q ttl:%v", kv.values["driver:online:7"], kv.ttls["driver:online:7"])
	}

	// Next read hits populated cache.
	online, err = cache.IsOnline(ctx, "7")
	if err != nil || !online || pgCalls != 1 {
		t.Fatalf("post-fill hit = (%v, %v, pgCalls=%d), want (true, nil, 1)", online, err, pgCalls)
	}

	// Redis error falls back to Postgres safely.
	kv.getErr = errors.New("redis connection reset")
	online, err = cache.IsOnline(ctx, "7")
	if err != nil || !online || pgCalls != 2 {
		t.Fatalf("error fallback = (%v, %v, pgCalls=%d), want (true, nil, 2)", online, err, pgCalls)
	}
}
