package hybrid

import (
	"context"
	"errors"
	"testing"

	chatpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/adapter/postgres"
	chatredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/adapter/redis"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
)

type durableStub struct {
	rooms            map[string]chatpostgres.LegacyRoomSnapshot
	messages         map[string][]domain.Message
	imported         []chatpostgres.LegacyRoomSnapshot
	importErr        error
	appendErr        error
	findMessageCalls int
}

func newDurableStub() *durableStub {
	return &durableStub{
		rooms:    make(map[string]chatpostgres.LegacyRoomSnapshot),
		messages: make(map[string][]domain.Message),
	}
}

func (d *durableStub) CreateRoom(_ context.Context, roomID, passengerID, driverID string) error {
	if _, exists := d.rooms[roomID]; !exists {
		d.rooms[roomID] = chatpostgres.LegacyRoomSnapshot{RoomID: roomID, PassengerID: passengerID, DriverID: driverID}
	}
	return nil
}

func (d *durableStub) Append(_ context.Context, message domain.Message) error {
	_, _, err := d.AppendWithParticipants(context.Background(), message)
	return err
}

func (d *durableStub) AppendWithParticipants(_ context.Context, message domain.Message) (string, string, error) {
	if d.appendErr != nil {
		return "", "", d.appendErr
	}
	room, ok := d.rooms[message.RoomID]
	if !ok {
		return "", "", domain.ErrRoomUnavailable
	}
	if room.Locked {
		return "", "", domain.ErrRoomLocked
	}
	d.messages[message.RoomID] = append(d.messages[message.RoomID], message)
	return room.PassengerID, room.DriverID, nil
}

func (d *durableStub) Messages(_ context.Context, roomID string) ([]domain.Message, error) {
	return d.messages[roomID], nil
}

func (d *durableStub) FindMessage(_ context.Context, roomID, messageID string) (domain.Message, bool, error) {
	d.findMessageCalls++
	for _, msg := range d.messages[roomID] {
		if msg.ID == messageID {
			return msg, true, nil
		}
	}
	return domain.Message{}, false, nil
}

func (d *durableStub) Resolve(_ context.Context, roomID string) error {
	room := d.rooms[roomID]
	room.Locked = true
	d.rooms[roomID] = room
	return nil
}

func (d *durableStub) RoomParticipants(_ context.Context, roomID string) (string, string, error) {
	room := d.rooms[roomID]
	return room.PassengerID, room.DriverID, nil
}

func (d *durableStub) IsMember(_ context.Context, roomID, userID string) (bool, error) {
	room := d.rooms[roomID]
	return userID != "" && (userID == room.PassengerID || userID == room.DriverID), nil
}

func (d *durableStub) IsLocked(_ context.Context, roomID string) (bool, error) {
	return d.rooms[roomID].Locked, nil
}

func (d *durableStub) MarkRead(_ context.Context, roomID, userID, through string) error {
	room := d.rooms[roomID]
	if userID == room.PassengerID {
		room.PassengerReadThrough = through
	} else if userID == room.DriverID {
		room.DriverReadThrough = through
	}
	d.rooms[roomID] = room
	return nil
}

func (d *durableStub) RoomSnapshot(_ context.Context, roomID string) (chatpostgres.LegacyRoomSnapshot, []domain.Message, bool, error) {
	room, ok := d.rooms[roomID]
	if !ok {
		return chatpostgres.LegacyRoomSnapshot{}, nil, false, nil
	}
	return room, d.messages[roomID], true, nil
}

func (d *durableStub) ImportRoomState(_ context.Context, snapshot chatpostgres.LegacyRoomSnapshot) error {
	if d.importErr != nil {
		return d.importErr
	}
	d.imported = append(d.imported, snapshot)
	return nil
}

type cacheStub struct {
	rooms           map[string]chatredis.StoredRoomState
	warmed          []string
	legacySnapshots []chatredis.StoredRoomState
	legacyKeys      []string
	expiredKeys     []string
	cacheErr        error
}

func newCacheStub() *cacheStub {
	return &cacheStub{rooms: make(map[string]chatredis.StoredRoomState)}
}

func (c *cacheStub) CreateRoom(_ context.Context, roomID, passengerID, driverID string) error {
	if c.cacheErr != nil {
		return c.cacheErr
	}
	c.rooms[roomID] = chatredis.StoredRoomState{RoomID: roomID, PassengerID: passengerID, DriverID: driverID}
	return nil
}

func (c *cacheStub) AppendWithParticipants(_ context.Context, message domain.Message) (string, string, error) {
	if c.cacheErr != nil {
		return "", "", c.cacheErr
	}
	room, ok := c.rooms[message.RoomID]
	if !ok {
		return "", "", domain.ErrRoomUnavailable
	}
	room.Messages = append(room.Messages, message)
	c.rooms[message.RoomID] = room
	return room.PassengerID, room.DriverID, nil
}

func (c *cacheStub) MessagesIfCached(_ context.Context, roomID string) ([]domain.Message, bool, error) {
	if c.cacheErr != nil {
		return nil, false, c.cacheErr
	}
	room, ok := c.rooms[roomID]
	if !ok {
		return nil, false, nil
	}
	return room.Messages, true, nil
}

func (c *cacheStub) FindMessage(_ context.Context, roomID, messageID string) (domain.Message, bool, error) {
	if c.cacheErr != nil {
		return domain.Message{}, false, c.cacheErr
	}
	room, ok := c.rooms[roomID]
	if !ok {
		return domain.Message{}, false, nil
	}
	for _, msg := range room.Messages {
		if msg.ID == messageID {
			return msg, true, nil
		}
	}
	return domain.Message{}, false, nil
}

func (c *cacheStub) Resolve(_ context.Context, roomID string) error {
	if c.cacheErr != nil {
		return c.cacheErr
	}
	room := c.rooms[roomID]
	room.Locked = true
	c.rooms[roomID] = room
	return nil
}

func (c *cacheStub) RoomParticipantsIfCached(_ context.Context, roomID string) (string, string, bool, error) {
	if c.cacheErr != nil {
		return "", "", false, c.cacheErr
	}
	room, ok := c.rooms[roomID]
	if !ok {
		return "", "", false, nil
	}
	return room.PassengerID, room.DriverID, true, nil
}

func (c *cacheStub) IsLockedIfCached(_ context.Context, roomID string) (bool, bool, error) {
	if c.cacheErr != nil {
		return false, false, c.cacheErr
	}
	room, ok := c.rooms[roomID]
	if !ok {
		return false, false, nil
	}
	return room.Locked, true, nil
}

func (c *cacheStub) MarkRead(_ context.Context, roomID, userID, through string) error {
	if c.cacheErr != nil {
		return c.cacheErr
	}
	return nil
}

func (c *cacheStub) WarmRoom(_ context.Context, state chatredis.StoredRoomState) error {
	if c.cacheErr != nil {
		return c.cacheErr
	}
	c.rooms[state.RoomID] = state
	c.warmed = append(c.warmed, state.RoomID)
	return nil
}

func (c *cacheStub) SnapshotLegacyPersistedRooms(context.Context) ([]chatredis.StoredRoomState, []string, error) {
	return c.legacySnapshots, c.legacyKeys, nil
}

func (c *cacheStub) ExpireKeys(_ context.Context, keys []string) error {
	c.expiredKeys = append(c.expiredKeys, keys...)
	return nil
}

func TestHybridStoreFallsBackToPostgresAndWarmsCacheOnEviction(t *testing.T) {
	durable := newDurableStub()
	cache := newCacheStub()
	store, err := NewStore(durable, cache)
	if err != nil {
		t.Fatal(err)
	}

	ctx := context.Background()
	if err := store.CreateRoom(ctx, "ride-1", "7", "8"); err != nil {
		t.Fatal(err)
	}
	if _, _, err := store.AppendWithParticipants(ctx, domain.Message{ID: "m1", RoomID: "ride-1", SenderID: "7", Body: "hello"}); err != nil {
		t.Fatal(err)
	}

	// Simulate Redis eviction under volatile-lru.
	delete(cache.rooms, "ride-1")

	msgs, err := store.Messages(ctx, "ride-1")
	if err != nil || len(msgs) != 1 || msgs[0].ID != "m1" {
		t.Fatalf("Messages() after cache eviction = (%#v, %v)", msgs, err)
	}
	if len(cache.warmed) != 1 || cache.warmed[0] != "ride-1" {
		t.Fatalf("expected cache warm on miss, got %v", cache.warmed)
	}

	// FindMessage falls back to Postgres even when cache fails.
	cache.cacheErr = errors.New("redis down")
	msg, found, err := store.FindMessage(ctx, "ride-1", "m1")
	if err != nil || !found || msg.Body != "hello" || durable.findMessageCalls != 1 {
		t.Fatalf("FindMessage() fallback = (%#v, %v, %v, calls=%d)", msg, found, err, durable.findMessageCalls)
	}
}

func TestHybridStoreMigratesLegacyRoomsBeforeExpiringKeys(t *testing.T) {
	durable := newDurableStub()
	cache := newCacheStub()
	cache.legacySnapshots = []chatredis.StoredRoomState{{
		RoomID:      "legacy-1",
		PassengerID: "7",
		DriverID:    "8",
		Locked:      true,
		Messages:    []domain.Message{{ID: "m1", SenderID: "7", Body: "old msg"}},
	}}
	cache.legacyKeys = []string{"chat:room:legacy-1", "chat:room:legacy-1:messages"}
	store, err := NewStore(durable, cache)
	if err != nil {
		t.Fatal(err)
	}

	durable.importErr = errors.New("transient db error")
	if err := store.MigrateLegacyRedisRooms(context.Background()); err == nil {
		t.Fatal("expected migration error when import fails")
	}
	if len(cache.expiredKeys) != 0 {
		t.Fatalf("keys expired despite failed import: %v", cache.expiredKeys)
	}

	durable.importErr = nil
	if err := store.MigrateLegacyRedisRooms(context.Background()); err != nil {
		t.Fatalf("MigrateLegacyRedisRooms() error = %v", err)
	}
	if len(durable.imported) != 1 || len(cache.expiredKeys) != 2 {
		t.Fatalf("imported=%d expiredKeys=%v", len(durable.imported), cache.expiredKeys)
	}
}
