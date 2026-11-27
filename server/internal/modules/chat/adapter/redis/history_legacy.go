package redis

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	redis "github.com/redis/go-redis/v9"
	"strings"
	"time"
)

// SnapshotLegacyPersistedRooms inspects chat:room:* keys lacking a TTL (-1),
// returning their decoded room state and messages so callers can durably
// persist them before expiring the Redis keys.
func (repository *HistoryStore) SnapshotLegacyPersistedRooms(ctx context.Context) ([]StoredRoomState, []string, error) {
	if err := repository.validate(); err != nil {
		return nil, nil, err
	}
	roomIDs := make(map[string]struct{})
	persistedKeys := make([]string, 0)
	var cursor uint64
	for {
		keys, next, err := repository.client.Scan(ctx, cursor, _roomKeyPrefix+"*", 200).Result()
		if err != nil {
			return nil, nil, fmt.Errorf("scan legacy chat history: %w", err)
		}
		if len(keys) > 0 {
			ttlCmds := make([]*redis.DurationCmd, len(keys))
			_, err = repository.client.Pipelined(ctx, func(pipe redis.Pipeliner) error {
				for i, key := range keys {
					ttlCmds[i] = pipe.TTL(ctx, key)
				}
				return nil
			})
			if err != nil {
				return nil, nil, fmt.Errorf("inspect legacy chat ttl: %w", err)
			}
			for i, key := range keys {
				ttl, ttlErr := ttlCmds[i].Result()
				if ttlErr != nil || ttl != -1 {
					continue
				}
				persistedKeys = append(persistedKeys, key)
				if !strings.HasSuffix(key, _messagesKeySuffix) && strings.HasPrefix(key, _roomKeyPrefix) {
					roomIDs[strings.TrimPrefix(key, _roomKeyPrefix)] = struct{}{}
				}
			}
		}
		if next == 0 {
			break
		}
		cursor = next
	}

	snapshots := make([]StoredRoomState, 0, len(roomIDs))
	for roomID := range roomIDs {
		var (
			fieldsCmd *redis.MapStringStringCmd
			itemsCmd  *redis.StringSliceCmd
		)
		_, err := repository.client.Pipelined(ctx, func(pipe redis.Pipeliner) error {
			fieldsCmd = pipe.HGetAll(ctx, roomKey(roomID))
			itemsCmd = pipe.LRange(ctx, messagesKey(roomID), 0, -1)
			return nil
		})
		if err != nil {
			return nil, nil, fmt.Errorf("read legacy chat room %q: %w", roomID, err)
		}
		fields, err := fieldsCmd.Result()
		if err != nil || len(fields) == 0 {
			continue
		}
		items, err := itemsCmd.Result()
		if err != nil {
			return nil, nil, fmt.Errorf("read legacy chat messages %q: %w", roomID, err)
		}
		passengerID := fields["passenger_id"]
		driverID := fields["driver_id"]
		snapshots = append(snapshots, StoredRoomState{
			RoomID:               roomID,
			PassengerID:          passengerID,
			DriverID:             driverID,
			Locked:               fields["locked"] == "1",
			HasMessages:          len(items) > 0,
			PassengerReadThrough: fields["read:"+passengerID],
			DriverReadThrough:    fields["read:"+driverID],
			Messages:             decodeStoredMessages(roomID, fields, items),
		})
	}
	return snapshots, persistedKeys, nil
}

// ExpireKeys applies finite TTLs to persisted legacy Redis chat keys so
// volatile-lru can evict cold rooms cleanly.
func (repository *HistoryStore) ExpireKeys(ctx context.Context, keys []string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	if len(keys) == 0 {
		return nil
	}
	_, err := repository.client.Pipelined(ctx, func(pipe redis.Pipeliner) error {
		for _, key := range keys {
			pipe.Expire(ctx, key, repository.resolvedDuration())
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("expire legacy chat history: %w", err)
	}
	return nil
}

// ExpireLegacyHistory transitions existing non-expiring chat keys in Redis to a finite TTL.
func (repository *HistoryStore) ExpireLegacyHistory(ctx context.Context) error {
	_, persistedKeys, err := repository.SnapshotLegacyPersistedRooms(ctx)
	if err != nil {
		return err
	}
	return repository.ExpireKeys(ctx, persistedKeys)
}

func marshalCanonicalMessage(message domain.Message) ([]byte, error) {
	if message.CreatedAt == "" {
		message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	}
	if message.ID == "" {
		message.ID = event.NewID()
	}
	return json.Marshal(struct {
		ID        string `json:"id"`
		ImageKey  string `json:"image_key,omitempty"`
		Text      string `json:"text"`
		SenderID  string `json:"sender_id"`
		CreatedAt string `json:"created_at"`
	}{
		ID:        message.ID,
		ImageKey:  message.ImageKey,
		Text:      message.Body,
		SenderID:  message.SenderID,
		CreatedAt: message.CreatedAt,
	})
}

func decodeStoredMessages(roomID string, fields map[string]string, items []string) []domain.Message {
	result := make([]domain.Message, 0, len(items))
	for _, item := range items {
		var value storedMessage
		if json.Unmarshal([]byte(item), &value) != nil {
			continue
		}
		body := value.Text
		if body == "" {
			body = value.LegacyMessage
		}
		senderID := value.SenderID
		if senderID == "" {
			senderID = value.LegacySenderID
		}
		createdAt := value.CreatedAt
		if createdAt == "" {
			createdAt = value.LegacyCreatedAt
		}
		if value.ID == "" {
			value.ID = fmt.Sprintf("legacy-%x", sha256.Sum256([]byte(senderID+"\n"+createdAt+"\n"+body)))
		}
		peerID := fields["passenger_id"]
		if senderID == peerID {
			peerID = fields["driver_id"]
		}
		created, createdErr := time.Parse(time.RFC3339Nano, createdAt)
		through, throughErr := time.Parse(time.RFC3339Nano, fields["read:"+peerID])
		seen := createdErr == nil && throughErr == nil && !created.IsZero() && !through.IsZero() && !created.After(through)
		result = append(result, domain.Message{
			ID:        value.ID,
			ImageKey:  value.ImageKey,
			Seen:      seen,
			RoomID:    roomID,
			SenderID:  senderID,
			Body:      body,
			CreatedAt: createdAt,
		})
	}
	return result
}
