//go:build integration

package redis

import (
	"context"
	"errors"
	"fmt"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	redisclient "github.com/redis/go-redis/v9"
)

func TestRetainedHistoryAndReadWatermarks(t *testing.T) {
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
	store := NewHistoryStore(client)
	if err := store.CreateRoom(ctx, "ride", "7", "8"); err != nil {
		t.Fatal(err)
	}
	for index := range 105 {
		err := store.Append(ctx, domain.Message{ID: fmt.Sprint(index), RoomID: "ride", SenderID: "7", Body: "retained", CreatedAt: time.Date(2026, 10, 23, 0, 0, index, 0, time.UTC).Format(time.RFC3339Nano)})
		if err != nil {
			t.Fatal(err)
		}
	}
	if err := client.Expire(ctx, roomKey("ride"), time.Hour).Err(); err != nil {
		t.Fatal(err)
	}
	if err := client.Expire(ctx, messagesKey("ride"), time.Hour).Err(); err != nil {
		t.Fatal(err)
	}
	if err := client.Set(ctx, "unrelated-cache", "value", time.Hour).Err(); err != nil {
		t.Fatal(err)
	}
	if err := store.RetainExistingHistory(ctx); err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{roomKey("ride"), messagesKey("ride")} {
		ttl, err := client.TTL(ctx, key).Result()
		if err != nil || ttl >= 0 {
			t.Fatalf("legacy history still expires: %s %v %v", key, ttl, err)
		}
	}
	if ttl := client.TTL(ctx, "unrelated-cache").Val(); ttl <= 0 {
		t.Fatal("retention changed unrelated cache expiry")
	}
	if err := store.Resolve(ctx, "ride"); err != nil {
		t.Fatal(err)
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
		t.Fatalf("retained history count %d, %v", len(messages), err)
	}
	if !messages[60].Seen || messages[61].Seen {
		t.Fatalf("incorrect read watermark: %#v / %#v", messages[60], messages[61])
	}
	for _, key := range []string{roomKey("ride"), messagesKey("ride")} {
		ttl, err := client.TTL(ctx, key).Result()
		if err != nil || ttl >= 0 {
			t.Fatalf("retained key expires: %s, %v, %v", key, ttl, err)
		}
	}
	if err := store.Append(ctx, domain.Message{RoomID: "ride", SenderID: "7", Body: "too late"}); !errors.Is(err, domain.ErrRoomLocked) {
		t.Fatalf("closed append: %v", err)
	}
}
