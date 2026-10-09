package tracking

import (
	"context"
	jsonv2 "encoding/json/v2"
	"fmt"
	"net"
	"os"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
	redis "github.com/redis/go-redis/v9"
)

const (
	_benchmarkRedisURLEnv = "DRIVEAPP_PERFORMANCE_REDIS_URL"
	_benchmarkRedisDB     = 15
	_benchmarkLatitude    = 14.5995
	_benchmarkLongitude   = 120.9842
)

func BenchmarkDriverLocationStoreNearby(b *testing.B) {
	for _, driverCount := range []int{20, 1000} {
		b.Run(fmt.Sprintf("drivers=%d", driverCount), func(b *testing.B) {
			client := openDriverLocationBenchmarkRedis(b)
			ctx := context.Background()
			store := NewDriverLocationStore(client)
			driverIDs := seedDriverLocationBenchmarkData(b, ctx, client, driverCount, false)
			b.Cleanup(func() {
				if err := removeDriverLocationBenchmarkData(ctx, client, driverIDs); err != nil {
					b.Errorf("remove benchmark data: %v", err)
				}
			})

			b.ReportAllocs()
			b.ResetTimer()
			for b.Loop() {
				points, err := store.Nearby(
					ctx,
					_benchmarkLatitude,
					_benchmarkLongitude,
					5,
				)
				if err != nil {
					b.Fatalf("Nearby() error = %v", err)
				}
				wantCount := min(driverCount, 20)
				if got := len(points); got != wantCount {
					b.Fatalf("Nearby() returned %d seeded drivers, want %d", got, wantCount)
				}
			}
		})
	}
}

func BenchmarkDriverLocationStoreNearbyStalePayloads(b *testing.B) {
	const driverCount = 20
	for _, staleCount := range []int{5, driverCount} {
		b.Run(fmt.Sprintf("stale=%d_of_%d", staleCount, driverCount), func(b *testing.B) {
			client := openDriverLocationBenchmarkRedis(b)
			ctx := context.Background()
			store := NewDriverLocationStore(client)
			b.ReportAllocs()
			b.ResetTimer()
			for b.Loop() {
				b.StopTimer()
				driverIDs := seedDriverLocationBenchmarkData(b, ctx, client, driverCount, false)
				stalePayloadKeys := make([]string, staleCount)
				// Seeded coordinates are ordered by distance, so these missing
				// payloads occupy the first nearby-result slots.
				for index := range staleCount {
					stalePayloadKeys[index] = driverLocationKey(driverIDs[index])
				}
				if err := client.Del(ctx, stalePayloadKeys...).Err(); err != nil {
					_ = removeDriverLocationBenchmarkData(ctx, client, driverIDs)
					b.Fatalf("remove stale benchmark payloads: %v", err)
				}
				b.StartTimer()

				points, err := store.Nearby(
					ctx,
					_benchmarkLatitude,
					_benchmarkLongitude,
					5,
				)
				b.StopTimer()
				if err != nil {
					_ = removeDriverLocationBenchmarkData(ctx, client, driverIDs)
					b.Fatalf("Nearby() error = %v", err)
				}
				if got, want := len(points), driverCount-staleCount; got != want {
					_ = removeDriverLocationBenchmarkData(ctx, client, driverIDs)
					b.Fatalf("Nearby() returned %d valid drivers, want %d", got, want)
				}
				if err := removeDriverLocationBenchmarkData(ctx, client, driverIDs); err != nil {
					b.Fatalf("remove benchmark data: %v", err)
				}
				b.StartTimer()
			}
		})
	}
}

func BenchmarkCleanupExpiredDrivers(b *testing.B) {
	for _, expiredCount := range []int{_locationCleanupBatchSize, 1000} {
		b.Run(fmt.Sprintf("expired=%d", expiredCount), func(b *testing.B) {
			client := openDriverLocationBenchmarkRedis(b)
			ctx := context.Background()
			store := NewDriverLocationStore(client)
			b.ReportAllocs()
			b.ResetTimer()
			for b.Loop() {
				b.StopTimer()
				driverIDs := seedDriverLocationBenchmarkData(b, ctx, client, expiredCount, true)
				b.StartTimer()

				removed, err := store.cleanupExpiredDrivers(ctx)
				b.StopTimer()
				if err != nil {
					b.Fatalf("cleanupExpiredDrivers() error = %v", err)
				}
				wantRemoved := min(expiredCount, _locationCleanupBatchSize)
				if removed != wantRemoved {
					b.Fatalf("removed = %d, want %d", removed, wantRemoved)
				}
				if err := removeDriverLocationBenchmarkData(ctx, client, driverIDs); err != nil {
					b.Fatalf("remove benchmark data: %v", err)
				}
				b.StartTimer()
			}
		})
	}
}

func openDriverLocationBenchmarkRedis(b *testing.B) *redis.Client {
	b.Helper()
	rawURL := os.Getenv(_benchmarkRedisURLEnv)
	if rawURL == "" {
		b.Skipf("set %s to an empty local Redis database %d", _benchmarkRedisURLEnv, _benchmarkRedisDB)
	}
	options, err := redis.ParseURL(rawURL)
	if err != nil {
		b.Fatalf("parse benchmark Redis URL: %v", err)
	}
	if options.DB != _benchmarkRedisDB {
		b.Fatalf("benchmark Redis URL must select dedicated database %d", _benchmarkRedisDB)
	}
	host, _, err := net.SplitHostPort(options.Addr)
	ip := net.ParseIP(host)
	if err != nil || ip == nil || !ip.IsLoopback() {
		b.Fatal("benchmark Redis URL must use a loopback IP address")
	}
	options.DialTimeout = 3 * time.Second
	options.ReadTimeout = 3 * time.Second
	options.WriteTimeout = 3 * time.Second
	client := redis.NewClient(options)
	if err := client.Ping(context.Background()).Err(); err != nil {
		_ = client.Close()
		b.Fatal("ping benchmark Redis")
	}
	keyCount, err := client.DBSize(context.Background()).Result()
	if err != nil {
		_ = client.Close()
		b.Fatalf("check benchmark database size: %v", err)
	}
	if keyCount != 0 {
		_ = client.Close()
		b.Fatalf("dedicated benchmark database %d must be empty; found %d keys", _benchmarkRedisDB, keyCount)
	}
	b.Cleanup(func() {
		if err := client.Close(); err != nil {
			b.Errorf("close benchmark Redis client: %v", err)
		}
	})
	return client
}

func seedDriverLocationBenchmarkData(
	b *testing.B,
	ctx context.Context,
	client *redis.Client,
	count int,
	expired bool,
) []string {
	b.Helper()
	ids := make([]string, count)
	now := time.Now().UTC()
	expiresAt := now.Add(time.Hour).UnixMilli()
	if expired {
		expiresAt = now.Add(-time.Minute).UnixMilli()
	}
	pipe := client.Pipeline()
	for index := range count {
		driverID := fmt.Sprintf("perf-%x-%04d", now.UnixNano(), index)
		ids[index] = driverID
		point := domain.DriverPoint{
			DriverID:   driverID,
			Latitude:   _benchmarkLatitude + float64(index/50)*0.00005,
			Longitude:  _benchmarkLongitude + float64(index%50)*0.00005,
			ObservedAt: now.Add(-time.Second),
		}
		payload, err := jsonv2.Marshal(point)
		if err != nil {
			b.Fatalf("marshal benchmark location: %v", err)
		}
		pipe.GeoAdd(ctx, _driverLocationsKey, &redis.GeoLocation{
			Longitude: point.Longitude,
			Latitude:  point.Latitude,
			Name:      driverID,
		})
		pipe.Set(ctx, driverLocationKey(driverID), payload, time.Hour)
		pipe.ZAdd(ctx, _driverLocationExpiryKey, redis.Z{Score: float64(expiresAt), Member: driverID})
		pipe.Set(ctx, driverLocationObservedAtKey(driverID), point.ObservedAt.UnixMilli(), time.Hour)
	}
	if _, err := pipe.Exec(ctx); err != nil {
		_ = removeDriverLocationBenchmarkData(ctx, client, ids)
		b.Fatalf("seed benchmark locations: %v", err)
	}
	return ids
}

func removeDriverLocationBenchmarkData(ctx context.Context, client *redis.Client, driverIDs []string) error {
	if len(driverIDs) == 0 {
		return nil
	}
	members := make([]any, len(driverIDs))
	keys := make([]string, 0, len(driverIDs)*2)
	for index, driverID := range driverIDs {
		members[index] = driverID
		keys = append(keys, driverLocationKey(driverID), driverLocationObservedAtKey(driverID))
	}
	pipe := client.Pipeline()
	pipe.ZRem(ctx, _driverLocationsKey, members...)
	pipe.ZRem(ctx, _driverLocationExpiryKey, members...)
	pipe.Del(ctx, keys...)
	_, err := pipe.Exec(ctx)
	return err
}
