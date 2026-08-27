package adapter

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	redis "github.com/redis/go-redis/v9"
)

const (
	chatRoomTTL       = 48 * time.Hour
	maxHistoryEntries = 100
)

type ChatHistoryStore struct{ client *redis.Client }

func NewChatHistoryStore(client *redis.Client) *ChatHistoryStore {
	return &ChatHistoryStore{client: client}
}

func (repository *ChatHistoryStore) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	// A room is a fixed 24-hour conversation window. Re-opening the same ride
	// must not reset its lock state or extend its expiry.
	exists, err := repository.client.Exists(ctx, roomKey(roomID)).Result()
	if err != nil {
		return err
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
	return err
}

func (repository *ChatHistoryStore) Append(ctx context.Context, message domain.Message) error {
	if message.CreatedAt == "" {
		message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	}
	payload, err := json.Marshal(map[string]string{"text": message.Body, "message": message.Body, "sender_id": message.SenderID, "senderId": message.SenderID, "created_at": message.CreatedAt, "createdAt": message.CreatedAt})
	if err != nil {
		return err
	}
	roomTTL, err := repository.client.TTL(ctx, roomKey(message.RoomID)).Result()
	if err != nil {
		return err
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
	return err
}

func (repository *ChatHistoryStore) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	items, err := repository.client.LRange(ctx, messagesKey(roomID), -maxHistoryEntries, -1).Result()
	if err != nil {
		return nil, err
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
		result = append(result, domain.Message{RoomID: roomID, SenderID: value.SenderID, Body: body, CreatedAt: value.CreatedAt})
	}
	return result, nil
}

func (repository *ChatHistoryStore) Resolve(ctx context.Context, roomID string) error {
	return repository.client.HSet(ctx, roomKey(roomID), "locked", "1").Err()
}

func (repository *ChatHistoryStore) IsMember(ctx context.Context, roomID, userID string) (bool, error) {
	fields, err := repository.client.HGetAll(ctx, roomKey(roomID)).Result()
	if err != nil {
		return false, err
	}
	return fields["passenger_id"] == userID || fields["driver_id"] == userID, nil
}

func (repository *ChatHistoryStore) IsLocked(ctx context.Context, roomID string) (bool, error) {
	value, err := repository.client.HGet(ctx, roomKey(roomID), "locked").Result()
	if err == redis.Nil {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return value == "1", nil
}

func (repository *ChatHistoryStore) RoomParticipants(ctx context.Context, roomID string) (string, string, error) {
	fields, err := repository.client.HGetAll(ctx, roomKey(roomID)).Result()
	if err != nil {
		return "", "", err
	}
	return fields["passenger_id"], fields["driver_id"], nil
}

func roomKey(roomID string) string     { return fmt.Sprintf("chat:room:%s", roomID) }
func messagesKey(roomID string) string { return fmt.Sprintf("chat:room:%s:messages", roomID) }
