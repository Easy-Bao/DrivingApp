package hybrid

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"

	chatpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/adapter/postgres"
	chatredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/adapter/redis"
	chatapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
)

type durableRoomStore interface {
	chatapp.RoomStore
	RoomSnapshot(ctx context.Context, roomID string) (chatpostgres.LegacyRoomSnapshot, []domain.Message, bool, error)
	ImportRoomState(ctx context.Context, snapshot chatpostgres.LegacyRoomSnapshot) error
}

type cacheRoomStore interface {
	CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error
	AppendWithParticipants(ctx context.Context, message domain.Message) (passengerID, driverID string, err error)
	MessagesIfCached(ctx context.Context, roomID string) ([]domain.Message, bool, error)
	FindMessage(ctx context.Context, roomID, messageID string) (domain.Message, bool, error)
	Resolve(ctx context.Context, roomID string) error
	RoomParticipantsIfCached(ctx context.Context, roomID string) (passengerID, driverID string, hit bool, err error)
	IsLockedIfCached(ctx context.Context, roomID string) (locked bool, hit bool, err error)
	MarkRead(ctx context.Context, roomID, userID, through string) error
	WarmRoom(ctx context.Context, state chatredis.StoredRoomState) error
	SnapshotLegacyPersistedRooms(ctx context.Context) ([]chatredis.StoredRoomState, []string, error)
	ExpireKeys(ctx context.Context, keys []string) error
}

// Store pairs durable PostgreSQL chat persistence with a bounded-TTL Redis hot cache.
type Store struct {
	durable durableRoomStore
	cache   cacheRoomStore
	logger  *slog.Logger
}

type Option func(*Store)

func WithLogger(logger *slog.Logger) Option {
	return func(store *Store) {
		if store != nil && logger != nil {
			store.logger = logger
		}
	}
}

var _ chatapp.RoomStore = (*Store)(nil)

func NewStore(durable durableRoomStore, cache cacheRoomStore, options ...Option) (*Store, error) {
	if durable == nil {
		return nil, errors.New("durable postgresql chat store is required")
	}
	store := &Store{
		durable: durable,
		cache:   cache,
		logger:  slog.Default(),
	}
	for _, option := range options {
		if option != nil {
			option(store)
		}
	}
	return store, nil
}

func (store *Store) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	if err := store.validate(); err != nil {
		return err
	}
	if err := store.durable.CreateRoom(ctx, roomID, passengerID, driverID); err != nil {
		return err
	}
	if store.cache != nil {
		if err := store.cache.CreateRoom(ctx, roomID, passengerID, driverID); err != nil {
			store.log().WarnContext(ctx, "warm redis chat room failed", "error", err, "room_id", roomID)
		}
	}
	return nil
}

func (store *Store) Append(ctx context.Context, message domain.Message) error {
	_, _, err := store.AppendWithParticipants(ctx, message)
	return err
}

func (store *Store) AppendWithParticipants(ctx context.Context, message domain.Message) (string, string, error) {
	if err := store.validate(); err != nil {
		return "", "", err
	}
	passengerID, driverID, err := store.durable.AppendWithParticipants(ctx, message)
	if err != nil {
		return "", "", err
	}
	if store.cache != nil {
		if _, _, cacheErr := store.cache.AppendWithParticipants(ctx, message); cacheErr != nil {
			if errors.Is(cacheErr, domain.ErrRoomUnavailable) {
				store.warmRoomBestEffort(ctx, message.RoomID)
			} else {
				store.log().WarnContext(ctx, "update redis chat cache after append failed", "error", cacheErr, "room_id", message.RoomID)
			}
		}
	}
	return passengerID, driverID, nil
}

func (store *Store) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	if err := store.validate(); err != nil {
		return nil, err
	}
	if store.cache != nil {
		messages, hit, err := store.cache.MessagesIfCached(ctx, roomID)
		if err == nil && hit {
			return messages, nil
		}
		if err != nil {
			store.log().WarnContext(ctx, "read redis chat messages failed; falling back to postgresql", "error", err, "room_id", roomID)
		}
	}
	snapshot, messages, found, err := store.durable.RoomSnapshot(ctx, roomID)
	if err != nil {
		return nil, err
	}
	if !found {
		return []domain.Message{}, nil
	}
	store.warmSnapshotBestEffort(ctx, snapshot, messages)
	return messages, nil
}

func (store *Store) FindMessage(ctx context.Context, roomID, messageID string) (domain.Message, bool, error) {
	if err := store.validate(); err != nil {
		return domain.Message{}, false, err
	}
	if store.cache != nil {
		message, found, err := store.cache.FindMessage(ctx, roomID, messageID)
		if err == nil && found {
			return message, true, nil
		}
		if err != nil {
			store.log().WarnContext(ctx, "find cached chat message failed; falling back to postgresql", "error", err, "room_id", roomID)
		}
	}
	return store.durable.FindMessage(ctx, roomID, messageID)
}

func (store *Store) Resolve(ctx context.Context, roomID string) error {
	if err := store.validate(); err != nil {
		return err
	}
	if err := store.durable.Resolve(ctx, roomID); err != nil {
		return err
	}
	if store.cache != nil {
		if err := store.cache.Resolve(ctx, roomID); err != nil {
			store.log().WarnContext(ctx, "lock redis chat cache room failed", "error", err, "room_id", roomID)
		}
	}
	return nil
}

func (store *Store) RoomParticipants(ctx context.Context, roomID string) (string, string, error) {
	if err := store.validate(); err != nil {
		return "", "", err
	}
	if store.cache != nil {
		passengerID, driverID, hit, err := store.cache.RoomParticipantsIfCached(ctx, roomID)
		if err == nil && hit {
			return passengerID, driverID, nil
		}
		if err != nil {
			store.log().WarnContext(ctx, "read cached chat participants failed; falling back to postgresql", "error", err, "room_id", roomID)
		}
	}
	snapshot, messages, found, err := store.durable.RoomSnapshot(ctx, roomID)
	if err != nil {
		return "", "", err
	}
	if !found {
		return "", "", nil
	}
	store.warmSnapshotBestEffort(ctx, snapshot, messages)
	return snapshot.PassengerID, snapshot.DriverID, nil
}

func (store *Store) IsMember(ctx context.Context, roomID, userID string) (bool, error) {
	if err := store.validate(); err != nil {
		return false, err
	}
	if userID == "" {
		return false, nil
	}
	passengerID, driverID, err := store.RoomParticipants(ctx, roomID)
	if err != nil {
		return false, err
	}
	return passengerID == userID || driverID == userID, nil
}

func (store *Store) IsLocked(ctx context.Context, roomID string) (bool, error) {
	if err := store.validate(); err != nil {
		return false, err
	}
	if store.cache != nil {
		locked, hit, err := store.cache.IsLockedIfCached(ctx, roomID)
		if err == nil && hit {
			return locked, nil
		}
		if err != nil {
			store.log().WarnContext(ctx, "read cached chat lock failed; falling back to postgresql", "error", err, "room_id", roomID)
		}
	}
	return store.durable.IsLocked(ctx, roomID)
}

func (store *Store) MarkRead(ctx context.Context, roomID, userID, through string) error {
	if err := store.validate(); err != nil {
		return err
	}
	if err := store.durable.MarkRead(ctx, roomID, userID, through); err != nil {
		return err
	}
	if store.cache != nil {
		if err := store.cache.MarkRead(ctx, roomID, userID, through); err != nil {
			store.log().WarnContext(ctx, "update redis chat read watermark failed", "error", err, "room_id", roomID)
		}
	}
	return nil
}

// MigrateLegacyRedisRooms copies non-expiring legacy Redis chat rooms and
// messages into PostgreSQL, then applies finite TTLs so Redis memory stays bounded.
func (store *Store) MigrateLegacyRedisRooms(ctx context.Context) error {
	if store == nil || store.durable == nil || store.cache == nil {
		return nil
	}
	snapshots, persistedKeys, err := store.cache.SnapshotLegacyPersistedRooms(ctx)
	if err != nil {
		return fmt.Errorf("snapshot legacy redis chat rooms: %w", err)
	}
	for _, snap := range snapshots {
		if strings.TrimSpace(snap.RoomID) == "" || strings.TrimSpace(snap.PassengerID) == "" || strings.TrimSpace(snap.DriverID) == "" {
			continue
		}
		if err := store.durable.ImportRoomState(ctx, chatpostgres.LegacyRoomSnapshot{
			RoomID:               snap.RoomID,
			PassengerID:          snap.PassengerID,
			DriverID:             snap.DriverID,
			Locked:               snap.Locked,
			PassengerReadThrough: snap.PassengerReadThrough,
			DriverReadThrough:    snap.DriverReadThrough,
			Messages:             snap.Messages,
		}); err != nil {
			return fmt.Errorf("import legacy chat room %q into postgresql: %w", snap.RoomID, err)
		}
	}
	if err := store.cache.ExpireKeys(ctx, persistedKeys); err != nil {
		return fmt.Errorf("apply finite ttl to migrated redis chat keys: %w", err)
	}
	return nil
}

func (store *Store) warmRoomBestEffort(ctx context.Context, roomID string) {
	if store.cache == nil {
		return
	}
	snapshot, messages, found, err := store.durable.RoomSnapshot(ctx, roomID)
	if err != nil || !found {
		return
	}
	store.warmSnapshotBestEffort(ctx, snapshot, messages)
}

func (store *Store) warmSnapshotBestEffort(
	ctx context.Context,
	snapshot chatpostgres.LegacyRoomSnapshot,
	messages []domain.Message,
) {
	if store.cache == nil {
		return
	}
	if err := store.cache.WarmRoom(ctx, chatredis.StoredRoomState{
		RoomID:               snapshot.RoomID,
		PassengerID:          snapshot.PassengerID,
		DriverID:             snapshot.DriverID,
		Locked:               snapshot.Locked,
		HasMessages:          len(messages) > 0,
		PassengerReadThrough: snapshot.PassengerReadThrough,
		DriverReadThrough:    snapshot.DriverReadThrough,
		Messages:             messages,
	}); err != nil {
		store.log().WarnContext(ctx, "warm redis chat cache failed", "error", err, "room_id", snapshot.RoomID)
	}
}

func (store *Store) validate() error {
	if store == nil || store.durable == nil {
		return errors.New("hybrid chat store is not initialized")
	}
	return nil
}

func (store *Store) log() *slog.Logger {
	if store != nil && store.logger != nil {
		return store.logger
	}
	return slog.Default()
}
