package postgres

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	chatapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

const _defaultMaxLoadedMessages int32 = 1000

// LegacyRoomSnapshot captures persisted Redis chat room state migrated into PostgreSQL.
type LegacyRoomSnapshot struct {
	RoomID               string
	PassengerID          string
	DriverID             string
	Locked               bool
	PassengerReadThrough string
	DriverReadThrough    string
	Messages             []domain.Message
}

// HistoryStore persists durable chat rooms, messages, and read watermarks in PostgreSQL.
type HistoryStore struct {
	pool        *pgxpool.Pool
	queries     *databasepostgres.Queries
	maxMessages int32
}

var _ chatapp.RoomStore = (*HistoryStore)(nil)

func NewHistoryStore(pool *pgxpool.Pool) (*HistoryStore, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &HistoryStore{
		pool:        pool,
		queries:     databasepostgres.New(pool),
		maxMessages: _defaultMaxLoadedMessages,
	}, nil
}

func (store *HistoryStore) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	if err := store.validate(); err != nil {
		return err
	}
	if err := store.queries.UpsertChatRoom(ctx, databasepostgres.UpsertChatRoomParams{
		RoomID:      roomID,
		PassengerID: passengerID,
		DriverID:    driverID,
	}); err != nil {
		return fmt.Errorf("create chat room: %w", err)
	}
	return nil
}

func (store *HistoryStore) Append(ctx context.Context, message domain.Message) error {
	_, _, err := store.AppendWithParticipants(ctx, message)
	return err
}

func (store *HistoryStore) AppendWithParticipants(ctx context.Context, message domain.Message) (string, string, error) {
	if err := store.validate(); err != nil {
		return "", "", err
	}
	createdAt := parseMessageTimeOrNow(message.CreatedAt)
	if message.ID == "" {
		message.ID = event.NewID()
	}

	tx, err := store.pool.Begin(ctx)
	if err != nil {
		return "", "", fmt.Errorf("begin append chat message transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, tx)
	}()

	txQueries := store.queries.WithTx(tx)
	room, err := txQueries.LockChatRoomForAppend(ctx, message.RoomID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", "", domain.ErrRoomUnavailable
		}
		return "", "", fmt.Errorf("lock chat room: %w", err)
	}
	if room.Locked {
		return "", "", domain.ErrRoomLocked
	}
	if message.SenderID != room.PassengerID && message.SenderID != room.DriverID {
		return "", "", domain.ErrForbidden
	}
	if err := txQueries.InsertChatMessage(ctx, databasepostgres.InsertChatMessageParams{
		ID:        message.ID,
		RoomID:    message.RoomID,
		SenderID:  message.SenderID,
		Body:      message.Body,
		ImageKey:  message.ImageKey,
		CreatedAt: pgtype.Timestamptz{Time: createdAt, Valid: true},
	}); err != nil {
		return "", "", fmt.Errorf("insert chat message: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return "", "", fmt.Errorf("commit chat message: %w", err)
	}
	return room.PassengerID, room.DriverID, nil
}

func (store *HistoryStore) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	if err := store.validate(); err != nil {
		return nil, err
	}
	room, err := store.queries.GetChatRoom(ctx, roomID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return []domain.Message{}, nil
		}
		return nil, fmt.Errorf("load chat room metadata: %w", err)
	}
	rows, err := store.queries.ListChatMessagesByRoom(ctx, databasepostgres.ListChatMessagesByRoomParams{
		RoomID: roomID,
		Limit:  store.limit(),
	})
	if err != nil {
		return nil, fmt.Errorf("list chat messages: %w", err)
	}
	result := make([]domain.Message, 0, len(rows))
	for _, row := range rows {
		result = append(result, mapPostgresMessage(row, room))
	}
	return result, nil
}

// RoomSnapshot returns the full persisted room metadata and recent messages for cache warming.
func (store *HistoryStore) RoomSnapshot(ctx context.Context, roomID string) (LegacyRoomSnapshot, []domain.Message, bool, error) {
	if err := store.validate(); err != nil {
		return LegacyRoomSnapshot{}, nil, false, err
	}
	room, err := store.queries.GetChatRoom(ctx, roomID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return LegacyRoomSnapshot{}, nil, false, nil
		}
		return LegacyRoomSnapshot{}, nil, false, fmt.Errorf("load chat room snapshot: %w", err)
	}
	rows, err := store.queries.ListChatMessagesByRoom(ctx, databasepostgres.ListChatMessagesByRoomParams{
		RoomID: roomID,
		Limit:  store.limit(),
	})
	if err != nil {
		return LegacyRoomSnapshot{}, nil, false, fmt.Errorf("list chat messages for snapshot: %w", err)
	}
	messages := make([]domain.Message, 0, len(rows))
	for _, row := range rows {
		messages = append(messages, mapPostgresMessage(row, room))
	}
	snapshot := LegacyRoomSnapshot{
		RoomID:      room.RoomID,
		PassengerID: room.PassengerID,
		DriverID:    room.DriverID,
		Locked:      room.Locked,
	}
	if room.PassengerReadThrough.Valid {
		snapshot.PassengerReadThrough = room.PassengerReadThrough.Time.UTC().Format("2006-01-02T15:04:05.000000000Z")
	}
	if room.DriverReadThrough.Valid {
		snapshot.DriverReadThrough = room.DriverReadThrough.Time.UTC().Format("2006-01-02T15:04:05.000000000Z")
	}
	return snapshot, messages, true, nil
}

func (store *HistoryStore) FindMessage(ctx context.Context, roomID, messageID string) (domain.Message, bool, error) {
	if err := store.validate(); err != nil {
		return domain.Message{}, false, err
	}
	row, err := store.queries.GetChatMessageByRoomAndID(ctx, databasepostgres.GetChatMessageByRoomAndIDParams{
		RoomID: roomID,
		ID:     messageID,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.Message{}, false, nil
		}
		return domain.Message{}, false, fmt.Errorf("find chat message: %w", err)
	}
	createdAt := ""
	if row.CreatedAt.Valid {
		createdAt = row.CreatedAt.Time.UTC().Format(time.RFC3339Nano)
	}
	return domain.Message{
		ID:        row.ID,
		ImageKey:  row.ImageKey,
		RoomID:    row.RoomID,
		SenderID:  row.SenderID,
		Body:      row.Body,
		CreatedAt: createdAt,
	}, true, nil
}

func (store *HistoryStore) Resolve(ctx context.Context, roomID string) error {
	if err := store.validate(); err != nil {
		return err
	}
	if err := store.queries.LockChatRoom(ctx, roomID); err != nil {
		return fmt.Errorf("resolve chat room: %w", err)
	}
	return nil
}

func (store *HistoryStore) RoomParticipants(ctx context.Context, roomID string) (string, string, error) {
	if err := store.validate(); err != nil {
		return "", "", err
	}
	room, err := store.queries.GetChatRoom(ctx, roomID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", "", nil
		}
		return "", "", fmt.Errorf("load chat room participants: %w", err)
	}
	return room.PassengerID, room.DriverID, nil
}

func (store *HistoryStore) IsMember(ctx context.Context, roomID, userID string) (bool, error) {
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

func (store *HistoryStore) IsLocked(ctx context.Context, roomID string) (bool, error) {
	if err := store.validate(); err != nil {
		return false, err
	}
	room, err := store.queries.GetChatRoom(ctx, roomID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		return false, fmt.Errorf("read chat room lock state: %w", err)
	}
	return room.Locked, nil
}

func (store *HistoryStore) MarkRead(ctx context.Context, roomID, userID, through string) error {
	if err := store.validate(); err != nil {
		return err
	}
	parsed, err := time.Parse(time.RFC3339Nano, strings.TrimSpace(through))
	if err != nil {
		return fmt.Errorf("parse chat read watermark: %w", err)
	}
	if err := store.queries.MarkChatRoomRead(ctx, databasepostgres.MarkChatRoomReadParams{
		RoomID:      roomID,
		UserID:      userID,
		ReadThrough: pgtype.Timestamptz{Time: parsed.UTC(), Valid: true},
	}); err != nil {
		return fmt.Errorf("mark chat room read: %w", err)
	}
	return nil
}

// ImportRoomState idempotently imports a legacy Redis chat room and its messages into PostgreSQL.
func (store *HistoryStore) ImportRoomState(ctx context.Context, snapshot LegacyRoomSnapshot) error {
	if err := store.validate(); err != nil {
		return err
	}
	if strings.TrimSpace(snapshot.RoomID) == "" {
		return errors.New("chat room id is required for migration")
	}

	tx, err := store.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin import chat room transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, tx)
	}()

	txQueries := store.queries.WithTx(tx)
	if err := txQueries.MigrateChatRoomState(ctx, databasepostgres.MigrateChatRoomStateParams{
		RoomID:               snapshot.RoomID,
		PassengerID:          snapshot.PassengerID,
		DriverID:             snapshot.DriverID,
		Locked:               snapshot.Locked,
		PassengerReadThrough: parseOptionalTimestamp(snapshot.PassengerReadThrough),
		DriverReadThrough:    parseOptionalTimestamp(snapshot.DriverReadThrough),
	}); err != nil {
		return fmt.Errorf("migrate chat room state: %w", err)
	}
	for _, msg := range snapshot.Messages {
		if msg.ID == "" {
			continue
		}
		createdAt := parseMessageTimeOrNow(msg.CreatedAt)
		if err := txQueries.InsertChatMessage(ctx, databasepostgres.InsertChatMessageParams{
			ID:        msg.ID,
			RoomID:    snapshot.RoomID,
			SenderID:  msg.SenderID,
			Body:      msg.Body,
			ImageKey:  msg.ImageKey,
			CreatedAt: pgtype.Timestamptz{Time: createdAt, Valid: true},
		}); err != nil {
			return fmt.Errorf("migrate chat message %q: %w", msg.ID, err)
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit migrated chat room: %w", err)
	}
	return nil
}

func (store *HistoryStore) validate() error {
	if store == nil || store.pool == nil || store.queries == nil {
		return errors.New("postgresql chat history store is not initialized")
	}
	return nil
}

func (store *HistoryStore) limit() int32 {
	if store != nil && store.maxMessages > 0 {
		return store.maxMessages
	}
	return _defaultMaxLoadedMessages
}

func mapPostgresMessage(row databasepostgres.ChatMessage, room databasepostgres.ChatRoom) domain.Message {
	createdAt := ""
	var createdTime time.Time
	if row.CreatedAt.Valid {
		createdTime = row.CreatedAt.Time.UTC()
		createdAt = createdTime.Format(time.RFC3339Nano)
	}
	peerReadThrough := room.PassengerReadThrough
	if row.SenderID == room.PassengerID {
		peerReadThrough = room.DriverReadThrough
	}
	seen := row.CreatedAt.Valid &&
		peerReadThrough.Valid &&
		!createdTime.IsZero() &&
		!peerReadThrough.Time.IsZero() &&
		!createdTime.After(peerReadThrough.Time.UTC())
	return domain.Message{
		ID:        row.ID,
		ImageKey:  row.ImageKey,
		Seen:      seen,
		RoomID:    row.RoomID,
		SenderID:  row.SenderID,
		Body:      row.Body,
		CreatedAt: createdAt,
	}
}

func parseMessageTimeOrNow(raw string) time.Time {
	if trimmed := strings.TrimSpace(raw); trimmed != "" {
		if parsed, err := time.Parse(time.RFC3339Nano, trimmed); err == nil {
			return parsed.UTC()
		}
	}
	return time.Now().UTC()
}

func parseOptionalTimestamp(raw string) pgtype.Timestamptz {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return pgtype.Timestamptz{}
	}
	parsed, err := time.Parse(time.RFC3339Nano, trimmed)
	if err != nil {
		return pgtype.Timestamptz{}
	}
	return pgtype.Timestamptz{Time: parsed.UTC(), Valid: true}
}
