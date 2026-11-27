package redis

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/domain"
	redis "github.com/redis/go-redis/v9"
)

func TestDriverLocationStoreWithTTLAndRemainingTTL(t *testing.T) {
	now := time.Date(2026, time.November, 20, 10, 0, 0, 0, time.UTC)
	defaultStore := NewDriverLocationStore(nil)
	if got := defaultStore.locationTTL(); got != _driverLocationTTL {
		t.Fatalf("default locationTTL() = %v, want %v", got, _driverLocationTTL)
	}

	customStore := NewDriverLocationStore(nil).WithTTL(90 * time.Second)
	if got := customStore.locationTTL(); got != 90*time.Second {
		t.Fatalf("custom locationTTL() = %v, want 90s", got)
	}
	customStore.WithTTL(0)
	if got := customStore.locationTTL(); got != 90*time.Second {
		t.Fatalf("WithTTL(0) overwrote TTL to %v, want 90s", got)
	}

	// Spooled 40s-old observation should keep only 5s of a 45s TTL.
	remaining, expiresAt, fresh := defaultStore.computeRemainingTTL(now.Add(-40*time.Second), now)
	if !fresh {
		t.Fatal("expected 40s-old point within 45s TTL to be fresh")
	}
	if remaining != 5*time.Second {
		t.Fatalf("remaining TTL = %v, want 5s", remaining)
	}
	if !expiresAt.Equal(now.Add(5 * time.Second)) {
		t.Fatalf("expiresAt = %v, want %v", expiresAt, now.Add(5*time.Second))
	}

	// Observation older than TTL is rejected as stale.
	if _, _, fresh := defaultStore.computeRemainingTTL(now.Add(-45*time.Second), now); fresh {
		t.Fatal("expected point at exact TTL age to be stale")
	}
	if _, _, fresh := defaultStore.computeRemainingTTL(now.Add(-60*time.Second), now); fresh {
		t.Fatal("expected point older than TTL to be stale")
	}

	// Slight future observation is capped to configured TTL.
	remaining, expiresAt, fresh = defaultStore.computeRemainingTTL(now.Add(5*time.Second), now)
	if !fresh || remaining != _driverLocationTTL || !expiresAt.Equal(now.Add(_driverLocationTTL)) {
		t.Fatalf("future observation = (%v, %v, %v), want capped TTL", remaining, expiresAt, fresh)
	}

	// Zero observation defaults to now.
	remaining, expiresAt, fresh = defaultStore.computeRemainingTTL(time.Time{}, now)
	if !fresh || remaining != _driverLocationTTL || !expiresAt.Equal(now.Add(_driverLocationTTL)) {
		t.Fatalf("zero observation = (%v, %v, %v), want full TTL", remaining, expiresAt, fresh)
	}
}

func TestDriverLocationStoreUpsertRejectsExpiredObservationBeforeRedisCall(t *testing.T) {
	// Pointing at an unused port verifies Upsert returns ErrStaleLocation locally
	// without issuing a Redis round-trip when remaining TTL has elapsed.
	client := redis.NewClient(&redis.Options{Addr: "127.0.0.1:0"})
	t.Cleanup(func() { _ = client.Close() })

	store := NewDriverLocationStore(client).WithTTL(30 * time.Second)
	err := store.Upsert(context.Background(), domain.DriverPoint{
		DriverID:   "driver-9",
		Latitude:   6.7,
		Longitude:  122.1,
		ObservedAt: time.Now().UTC().Add(-31 * time.Second),
	})
	if !errors.Is(err, domain.ErrStaleLocation) {
		t.Fatalf("Upsert() error = %v, want domain.ErrStaleLocation", err)
	}
}
