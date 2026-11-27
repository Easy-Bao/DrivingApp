//go:build integration

package redis

import (
	"context"
	"errors"
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	redisclient "github.com/redis/go-redis/v9"
)

func TestCachedHistoryFiniteTTLsAndReadWatermarks(t *testing.T) {
	binary, err := exec.LookPath("redis-server")
	if err != nil {
		t.Skip("redis-server is required")
	}
	socket := filepath.Join(t.TempDir(), "redis.sock")
	process := exec.Command(binary, "--port", "0", "--unixsocket", socket, "--save", "", "--appendonly", "no")
	if err := process.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = process.Process.Kill(); _ = process.Wait() })
	client := redisclient.NewClient(&redisclient.Options{Network: "unix", Addr: socket})
	t.Cleanup(func() { _ = client.Close() })
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	for client.Ping(ctx).Err() != nil {
		if ctx.Err() != nil {
			t.Fatal(ctx.Err())
		}
		time.Sleep(10 * time.Millisecond)
	}

	store := NewHistoryStore(client, WithActiveTTL(10*time.Minute), WithResolvedTTL(2*time.Minute))
	if _, _, err := store.AppendWithParticipants(ctx, domain.Message{ID: "missing", RoomID: "ride", SenderID: "7", Body: "before open"}); !errors.Is(err, domain.ErrRoomUnavailable) {
		t.Fatalf("missing room append = %v, want %v", err, domain.ErrRoomUnavailable)
	}
	if err := store.CreateRoom(ctx, "ride", "7", "8"); err != nil {
		t.Fatal(err)
	}
	if member, err := store.IsMember(ctx, "ride", ""); err != nil || member {
		t.Fatalf("empty member = %v, %v", member, err)
	}
	if member, err := store.IsMember(ctx, "ride", "7"); err != nil || !member {
		t.Fatalf("passenger member = %v, %v", member, err)
	}
	if member, err := store.IsMember(ctx, "ride", "outsider"); err != nil || member {
		t.Fatalf("outsider member = %v, %v", member, err)
	}
	if _, _, err := store.AppendWithParticipants(ctx, domain.Message{ID: "bad", RoomID: "ride", SenderID: "outsider", Body: "denied"}); !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("outsider append = %v, want %v", err, domain.ErrForbidden)
	}
	for index := range 105 {
		passenger, driver, err := store.AppendWithParticipants(ctx, domain.Message{
			ID:        fmt.Sprint(index),
			RoomID:    "ride",
			SenderID:  "7",
			Body:      "cached",
			CreatedAt: time.Date(2026, 10, 23, 0, 0, index, 0, time.UTC).Format(time.RFC3339Nano),
		})
		if err != nil {
			t.Fatal(err)
		}
		if passenger != "7" || driver != "8" {
			t.Fatalf("append participants = %q/%q, want 7/8", passenger, driver)
		}
	}

	rawFirst, err := client.LIndex(ctx, messagesKey("ride"), 0).Result()
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(rawFirst, `"senderId"`) || strings.Contains(rawFirst, `"createdAt"`) || strings.Contains(rawFirst, `"message"`) {
		t.Fatalf("Redis payload still stores duplicate legacy aliases: %s", rawFirst)
	}

	for _, key := range []string{roomKey("ride"), messagesKey("ride")} {
		ttl, err := client.TTL(ctx, key).Result()
		if err != nil || ttl <= 0 || ttl > 10*time.Minute {
			t.Fatalf("active room key ttl = (%v, %v), want positive finite TTL", ttl, err)
		}
	}

	// Simulate legacy persisted keys (-1 TTL) and verify ExpireLegacyHistory adds finite TTLs.
	if err := client.Persist(ctx, roomKey("ride")).Err(); err != nil {
		t.Fatal(err)
	}
	if err := client.Persist(ctx, messagesKey("ride")).Err(); err != nil {
		t.Fatal(err)
	}
	if err := client.Set(ctx, "unrelated-cache", "value", time.Hour).Err(); err != nil {
		t.Fatal(err)
	}
	if err := store.ExpireLegacyHistory(ctx); err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{roomKey("ride"), messagesKey("ride")} {
		ttl, err := client.TTL(ctx, key).Result()
		if err != nil || ttl <= 0 {
			t.Fatalf("migrated key still missing TTL: %s %v %v", key, ttl, err)
		}
	}
	if ttl := client.TTL(ctx, "unrelated-cache").Val(); ttl <= 0 {
		t.Fatal("legacy expiry touched unrelated cache key")
	}

	if err := store.Resolve(ctx, "ride"); err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{roomKey("ride"), messagesKey("ride")} {
		ttl, err := client.TTL(ctx, key).Result()
		if err != nil || ttl <= 0 || ttl > 2*time.Minute {
			t.Fatalf("resolved key ttl = (%v, %v), want finite resolved TTL", ttl, err)
		}
	}
	if err := store.CreateRoom(ctx, "ride", "attacker", "another"); err != nil {
		t.Fatal(err)
	}
	passenger, driver, err := store.RoomParticipants(ctx, "ride")
	if err != nil || passenger != "7" || driver != "8" {
		t.Fatalf("participants changed: %s/%s, %v", passenger, driver, err)
	}
	if err := store.MarkRead(ctx, "ride", "8", "2026-10-23T00:01:00.000000000Z"); err != nil {
		t.Fatal(err)
	}
	if err := store.MarkRead(ctx, "ride", "8", "2026-10-23T00:00:30.000000000Z"); err != nil {
		t.Fatal(err)
	}
	messages, err := store.Messages(ctx, "ride")
	if err != nil || len(messages) != 105 {
		t.Fatalf("history count %d, %v", len(messages), err)
	}
	if !messages[60].Seen || messages[61].Seen {
		t.Fatalf("incorrect read watermark: %#v / %#v", messages[60], messages[61])
	}
	foundMsg, found, err := store.FindMessage(ctx, "ride", "42")
	if err != nil || !found || foundMsg.ID != "42" {
		t.Fatalf("FindMessage(42) = (%#v, %v, %v)", foundMsg, found, err)
	}
	if _, found, err := store.FindMessage(ctx, "ride", "does-not-exist"); err != nil || found {
		t.Fatalf("FindMessage(missing) = (%v, %v), want (false, nil)", found, err)
	}
	if err := store.Append(ctx, domain.Message{RoomID: "ride", SenderID: "7", Body: "too late"}); !errors.Is(err, domain.ErrRoomLocked) {
		t.Fatalf("closed append: %v", err)
	}
}
