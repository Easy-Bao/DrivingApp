package adapter

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/chat/domain"
	chatports "github.com/Easy-Bao/DrivingApp/server/internal/chat/ports"
	redis "github.com/redis/go-redis/v9"
)

const (
	chatRoomTTL       = 48 * time.Hour
	maxHistoryEntries = 100
)

// ChatHistoryStore is the Redis adapter for the bounded chat-room history port.
type ChatHistoryStore struct{ client *redis.Client }

var _ chatports.RoomStore = (*ChatHistoryStore)(nil)

func NewChatHistoryStore(client *redis.Client) *ChatHistoryStore {
	return &ChatHistoryStore{client: client}
}

// CreateRoom creates a participant-scoped room without extending an existing
// room's expiry.
func (repository *ChatHistoryStore) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	// A room is a fixed 48-hour conversation window. Re-opening the same ride
	// must not reset its lock state or extend its expiry.
	exists, err := repository.client.Exists(ctx, roomKey(roomID)).Result()
	if err != nil {
		return fmt.Errorf("check chat room existence: %w", err)
	}
	if exists > 0 {
		return nil
	}
	createdAt := time.Now().UTC().Format(time.RFC3339Nano)
	_, err = repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.HSet(ctx, roomKey(roomID), map[string]any{
			"passenger_id": passengerID,
			"driver_id":    driverID,
			"locked":       "0",
			"created_at":   createdAt,
		})
		pipe.Expire(ctx, roomKey(roomID), chatRoomTTL)
		return nil
	})
	if err != nil {
		return fmt.Errorf("create chat room: %w", err)
	}
	return nil
}

// Append stores a message and preserves the room's remaining lifetime.
func (repository *ChatHistoryStore) Append(ctx context.Context, message domain.Message) error {
	if err := repository.validate(); err != nil {
		return err
	}
	if message.CreatedAt == "" {
		message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	}
	payload, err := json.Marshal(map[string]string{
		"text":       message.Body,
		"message":    message.Body,
		"sender_id":  message.SenderID,
		"senderId":   message.SenderID,
		"created_at": message.CreatedAt,
		"createdAt":  message.CreatedAt,
	})
	if err != nil {
		return fmt.Errorf("marshal chat message: %w", err)
	}
	roomTTL, err := repository.client.TTL(ctx, roomKey(message.RoomID)).Result()
	if err != nil {
		return fmt.Errorf("read chat room ttl: %w", err)
	}
	if roomTTL == time.Duration(-2) {
		return domain.ErrRoomUnavailable
	}
	if roomTTL < 0 {
		roomTTL = chatRoomTTL
	}
	_, err = repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.RPush(ctx, messagesKey(message.RoomID), payload)
		pipe.LTrim(ctx, messagesKey(message.RoomID), -maxHistoryEntries, -1)
		// The list does not exist until RPush runs, so its TTL must be applied
		// in the same transaction using the room's remaining lifetime.
		pipe.Expire(ctx, messagesKey(message.RoomID), roomTTL)
		return nil
	})
	if err != nil {
		return fmt.Errorf("append chat message: %w", err)
	}
	return nil
}

// Messages returns valid entries from the bounded room history. Malformed
// stored entries are ignored so one bad record cannot hide later messages.
func (repository *ChatHistoryStore) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	if err := repository.validate(); err != nil {
		return nil, err
	}
	items, err := repository.client.LRange(ctx, messagesKey(roomID), -maxHistoryEntries, -1).Result()
	if err != nil {
		return nil, fmt.Errorf("load chat messages: %w", err)
	}
	result := make([]domain.Message, 0, len(items))
	for _, item := range items {
		var value struct {
			Text      string `json:"text"`
			Message   string `json:"message"`
			SenderID  string `json:"sender_id"`
			CreatedAt string `json:"created_at"`
		}
		if json.Unmarshal([]byte(item), &value) != nil {
			continue
		}
		body := value.Text
		if body == "" {
			body = value.Message
		}
		result = append(result, domain.Message{
			RoomID:    roomID,
			SenderID:  value.SenderID,
			Body:      body,
			CreatedAt: value.CreatedAt,
		})
	}
	return result, nil
}

// Resolve marks a room closed for the service's subsequent message checks.
func (repository *ChatHistoryStore) Resolve(ctx context.Context, roomID string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	if err := repository.client.HSet(ctx, roomKey(roomID), "locked", "1").Err(); err != nil {
		return fmt.Errorf("resolve chat room: %w", err)
	}
	return nil
}

func (repository *ChatHistoryStore) IsMember(ctx context.Context, roomID, userID string) (bool, error) {
	if err := repository.validate(); err != nil {
		return false, err
	}
	fields, err := repository.client.HGetAll(ctx, roomKey(roomID)).Result()
	if err != nil {
		return false, fmt.Errorf("load chat room participants: %w", err)
	}
	return fields["passenger_id"] == userID || fields["driver_id"] == userID, nil
}

func (repository *ChatHistoryStore) IsLocked(ctx context.Context, roomID string) (bool, error) {
	if err := repository.validate(); err != nil {
		return false, err
	}
	value, err := repository.client.HGet(ctx, roomKey(roomID), "locked").Result()
	if errors.Is(err, redis.Nil) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("read chat room lock state: %w", err)
	}
	return value == "1", nil
}

func (repository *ChatHistoryStore) RoomParticipants(ctx context.Context, roomID string) (string, string, error) {
	if err := repository.validate(); err != nil {
		return "", "", err
	}
	fields, err := repository.client.HGetAll(ctx, roomKey(roomID)).Result()
	if err != nil {
		return "", "", fmt.Errorf("load chat room participants: %w", err)
	}
	return fields["passenger_id"], fields["driver_id"], nil
}

func roomKey(roomID string) string     { return "chat:room:" + roomID }
func messagesKey(roomID string) string { return "chat:room:" + roomID + ":messages" }

func (repository *ChatHistoryStore) validate() error {
	if repository == nil || repository.client == nil {
		return errors.New("chat history store is not configured")
	}
	return nil
}
