package redis

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	redisclient "github.com/redis/go-redis/v9"
)

type PendingRegistrationStore struct{ client *redisclient.Client }

func NewPendingRegistrationStore(client *redisclient.Client) *PendingRegistrationStore {
	return &PendingRegistrationStore{client: client}
}

func (store *PendingRegistrationStore) Put(ctx context.Context, registration domain.PendingRegistration, ttl time.Duration) error {
	payload, err := json.Marshal(registration)
	if err != nil {
		return err
	}
	return store.client.Set(ctx, pendingKey(registration.Email), payload, ttl).Err()
}

func (store *PendingRegistrationStore) Get(ctx context.Context, email string) (domain.PendingRegistration, error) {
	payload, err := store.client.Get(ctx, pendingKey(email)).Bytes()
	if errors.Is(err, redisclient.Nil) {
		return domain.PendingRegistration{}, domain.ErrPendingRegistrationNotFound
	}
	if err != nil {
		return domain.PendingRegistration{}, err
	}
	var registration domain.PendingRegistration
	if err := json.Unmarshal(payload, &registration); err != nil {
		return domain.PendingRegistration{}, err
	}
	return registration, nil
}

func (store *PendingRegistrationStore) Delete(ctx context.Context, email string) error {
	return store.client.Del(ctx, pendingKey(email)).Err()
}

func pendingKey(email string) string {
	return "auth:registration:pending:" + strings.ToLower(strings.TrimSpace(email))
}
