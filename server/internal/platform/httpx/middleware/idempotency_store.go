package middleware

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	redisclient "github.com/redis/go-redis/v9"
	"sync"
	"time"
)

type IdempotencyStore interface {
	Get(ctx context.Context, key string) ([]byte, error)
	Set(ctx context.Context, key string, value []byte, expiration time.Duration) error
	SetNX(ctx context.Context, key string, value []byte, expiration time.Duration) (bool, error)
	DeleteIfValue(ctx context.Context, key string, value []byte) error
}

type CacheIdempotencyStore struct {
	client *redisclient.Client
}

var _ IdempotencyStore = (*CacheIdempotencyStore)(nil)

func NewCacheIdempotencyStore(client *redisclient.Client) *CacheIdempotencyStore {
	return &CacheIdempotencyStore{client: client}
}

func (store *CacheIdempotencyStore) Get(ctx context.Context, key string) ([]byte, error) {
	if store == nil || store.client == nil {
		return nil, fmt.Errorf("redis idempotency store is not configured")
	}
	if ctx == nil {
		return nil, errors.New("idempotency context is nil")
	}
	value, err := store.client.Get(ctx, key).Bytes()
	if errors.Is(err, redisclient.Nil) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get idempotency response: %w", err)
	}
	return value, nil
}

func (store *CacheIdempotencyStore) Set(ctx context.Context, key string, value []byte, expiration time.Duration) error {
	if store == nil || store.client == nil {
		return fmt.Errorf("redis idempotency store is not configured")
	}
	if ctx == nil {
		return errors.New("idempotency context is nil")
	}
	if err := store.client.Set(
		ctx,
		key,
		value,
		expiration,
	).Err(); err != nil {
		return fmt.Errorf("set idempotency response: %w", err)
	}
	return nil
}

func (store *CacheIdempotencyStore) SetNX(
	ctx context.Context,
	key string,
	value []byte,
	expiration time.Duration,
) (bool, error) {
	if store == nil || store.client == nil {
		return false, fmt.Errorf("redis idempotency store is not configured")
	}
	if ctx == nil {
		return false, errors.New("idempotency context is nil")
	}
	acquired, err := store.client.SetNX(
		ctx,
		key,
		value,
		expiration,
	).Result()
	if err != nil {
		return false, fmt.Errorf("acquire idempotency lock: %w", err)
	}
	return acquired, nil
}

var _releaseIdempotencyLockScript = redisclient.NewScript(`
if redis.call("GET", KEYS[1]) == ARGV[1] then
    return redis.call("DEL", KEYS[1])
else
    return 0
end`)

func (store *CacheIdempotencyStore) DeleteIfValue(ctx context.Context, key string, value []byte) error {
	if store == nil || store.client == nil {
		return fmt.Errorf("redis idempotency store is not configured")
	}
	if ctx == nil {
		return errors.New("idempotency context is nil")
	}
	if err := _releaseIdempotencyLockScript.Run(
		ctx,
		store.client,
		[]string{key},
		value,
	).Err(); err != nil {
		return fmt.Errorf("release idempotency lock: %w", err)
	}
	return nil
}

const (
	_defaultMemoryIdempotencyCapacity  = 4096
	_memoryIdempotencyEvictionInterval = time.Minute
)

type MemoryIdempotencyStore struct {
	mu           sync.Mutex
	entries      map[string]memoryIdempotencyEntry
	capacity     int
	lastEviction time.Time
}

var _ IdempotencyStore = (*MemoryIdempotencyStore)(nil)

type memoryIdempotencyEntry struct {
	value   []byte
	expires time.Time
}

func (store *MemoryIdempotencyStore) evictLocked(now time.Time) {
	if len(store.entries) == 0 {
		return
	}
	capacity := store.capacity
	if capacity <= 0 {
		capacity = _defaultMemoryIdempotencyCapacity
	}
	if len(store.entries) >= capacity || now.Sub(store.lastEviction) >= _memoryIdempotencyEvictionInterval {
		store.lastEviction = now
		for k, v := range store.entries {
			if !now.Before(v.expires) {
				delete(store.entries, k)
			}
		}
	}
	if len(store.entries) >= capacity {
		target := (capacity * 9) / 10
		if target >= capacity {
			target = capacity - 1
		}
		for len(store.entries) > target {
			var oldestKey string
			var oldestExpires time.Time
			for k, v := range store.entries {
				if oldestKey == "" || v.expires.Before(oldestExpires) {
					oldestKey = k
					oldestExpires = v.expires
				}
			}
			if oldestKey == "" {
				break
			}
			delete(store.entries, oldestKey)
		}
	}
}

func NewMemoryIdempotencyStore() *MemoryIdempotencyStore {
	return NewMemoryIdempotencyStoreWithCapacity(_defaultMemoryIdempotencyCapacity)
}

func NewMemoryIdempotencyStoreWithCapacity(capacity int) *MemoryIdempotencyStore {
	if capacity <= 0 {
		capacity = _defaultMemoryIdempotencyCapacity
	}
	return &MemoryIdempotencyStore{
		entries:  make(map[string]memoryIdempotencyEntry),
		capacity: capacity,
	}
}

func (store *MemoryIdempotencyStore) Get(ctx context.Context, key string) ([]byte, error) {
	if store == nil {
		return nil, errors.New("memory idempotency store is not configured")
	}
	if err := memoryIdempotencyContextError(ctx); err != nil {
		return nil, err
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.entries == nil {
		return nil, nil
	}
	entry, ok := store.entries[key]
	if !ok || !time.Now().Before(entry.expires) {
		delete(store.entries, key)
		return nil, nil
	}
	return append([]byte(nil), entry.value...), nil
}

func (store *MemoryIdempotencyStore) Set(
	ctx context.Context,
	key string,
	value []byte,
	expiration time.Duration,
) error {
	if store == nil {
		return errors.New("memory idempotency store is not configured")
	}
	if err := memoryIdempotencyContextError(ctx); err != nil {
		return err
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.entries == nil {
		store.entries = make(map[string]memoryIdempotencyEntry)
	}
	now := time.Now()
	store.evictLocked(now)
	store.entries[key] = memoryIdempotencyEntry{value: append([]byte(nil), value...), expires: now.Add(expiration)}
	return nil
}

func (store *MemoryIdempotencyStore) SetNX(
	ctx context.Context,
	key string,
	value []byte,
	expiration time.Duration,
) (bool, error) {
	if store == nil {
		return false, errors.New("memory idempotency store is not configured")
	}
	if err := memoryIdempotencyContextError(ctx); err != nil {
		return false, err
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.entries == nil {
		store.entries = make(map[string]memoryIdempotencyEntry)
	}
	now := time.Now()
	store.evictLocked(now)
	if entry, ok := store.entries[key]; ok && now.Before(entry.expires) {
		return false, nil
	}
	store.entries[key] = memoryIdempotencyEntry{value: append([]byte(nil), value...), expires: now.Add(expiration)}
	return true, nil
}

func (store *MemoryIdempotencyStore) DeleteIfValue(ctx context.Context, key string, value []byte) error {
	if store == nil {
		return errors.New("memory idempotency store is not configured")
	}
	if err := memoryIdempotencyContextError(ctx); err != nil {
		return err
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.entries == nil {
		return nil
	}
	entry, ok := store.entries[key]
	if ok && bytes.Equal(entry.value, value) {
		delete(store.entries, key)
	}
	return nil
}

func memoryIdempotencyContextError(ctx context.Context) error {
	if ctx == nil {
		return errors.New("idempotency context is nil")
	}
	return ctx.Err()
}
