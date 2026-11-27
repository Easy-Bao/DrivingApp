package middleware

import (
	"context"
	"errors"
	"fmt"
	redisclient "github.com/redis/go-redis/v9"
	"sync"
	"time"
)

type CounterStore interface {
	Increment(ctx context.Context, key string, window time.Duration) (int64, error)
}

type CacheCounterStore struct {
	client *redisclient.Client
}

var _ CounterStore = (*CacheCounterStore)(nil)

var _atomicIncrementScript = redisclient.NewScript(`
local count = redis.call('INCR', KEYS[1])
if count == 1 then
  redis.call('PEXPIRE', KEYS[1], ARGV[1])
end
return count
`)

func NewCacheCounterStore(client *redisclient.Client) *CacheCounterStore {
	return &CacheCounterStore{client: client}
}

func (store *CacheCounterStore) Increment(ctx context.Context, key string, window time.Duration) (int64, error) {
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
	count, err := _atomicIncrementScript.Run(
		ctx,
		store.client,
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
	capacity   int
	operations uint64
}

var _ CounterStore = (*MemoryCounterStore)(nil)

type memoryCounter struct {
	count   int64
	expires time.Time
}

const (
	_memoryCounterCleanupInterval = 128
	_defaultMemoryCounterCapacity = 50_000
)

func NewMemoryCounterStore() *MemoryCounterStore {
	return &MemoryCounterStore{
		entries:  make(map[string]memoryCounter),
		capacity: _defaultMemoryCounterCapacity,
	}
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
	capacity := store.capacity
	if capacity <= 0 {
		capacity = _defaultMemoryCounterCapacity
	}
	if store.operations%_memoryCounterCleanupInterval == 0 || len(store.entries) >= capacity {
		for entryKey, entry := range store.entries {
			if !now.Before(entry.expires) {
				delete(store.entries, entryKey)
			}
		}
	}
	entry, ok := store.entries[key]
	if !ok || !now.Before(entry.expires) {
		if !ok && len(store.entries) >= capacity {
			target := (capacity * 9) / 10
			if target >= capacity {
				target = capacity - 1
			}
			for len(store.entries) > target {
				var oldestKey string
				var oldestExpires time.Time
				for entryKey, item := range store.entries {
					if oldestKey == "" || item.expires.Before(oldestExpires) {
						oldestKey = entryKey
						oldestExpires = item.expires
					}
				}
				if oldestKey == "" {
					break
				}
				delete(store.entries, oldestKey)
			}
		}
		entry = memoryCounter{expires: now.Add(window)}
	}
	entry.count++
	store.entries[key] = entry
	return entry.count, nil
}
