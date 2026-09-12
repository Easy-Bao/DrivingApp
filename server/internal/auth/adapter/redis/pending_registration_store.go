package redis

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	redisclient "github.com/redis/go-redis/v9"
)

type PendingRegistrationStore struct{ client *redisclient.Client }

func NewPendingRegistrationStore(client *redisclient.Client) *PendingRegistrationStore {
	return &PendingRegistrationStore{client: client}
}

func (store *PendingRegistrationStore) Put(
	ctx context.Context,
	registration domain.PendingRegistration,
	ttl time.Duration,
) error {
	if err := store.validate(); err != nil {
		return err
	}
	payload, err := json.Marshal(registration)
	if err != nil {
		return fmt.Errorf("marshal pending registration: %w", err)
	}
	if err := store.client.Set(
		ctx,
		pendingKey(registration.Email),
		payload,
		ttl,
	).Err(); err != nil {
		return fmt.Errorf("store pending registration: %w", err)
	}
	return nil
}

func (store *PendingRegistrationStore) Get(ctx context.Context, email string) (domain.PendingRegistration, error) {
	if err := store.validate(); err != nil {
		return domain.PendingRegistration{}, err
	}
	payload, err := store.client.Get(ctx, pendingKey(email)).Bytes()
	if errors.Is(err, redisclient.Nil) {
		return domain.PendingRegistration{}, domain.ErrPendingRegistrationNotFound
	}
	if err != nil {
		return domain.PendingRegistration{}, fmt.Errorf("get pending registration: %w", err)
	}
	var registration domain.PendingRegistration
	if err := json.Unmarshal(payload, &registration); err != nil {
		return domain.PendingRegistration{}, fmt.Errorf("decode pending registration: %w", err)
	}
	return registration, nil
}

func (store *PendingRegistrationStore) Delete(ctx context.Context, email string) error {
	if err := store.validate(); err != nil {
		return err
	}
	if err := store.client.Del(ctx, pendingKey(email)).Err(); err != nil {
		return fmt.Errorf("delete pending registration: %w", err)
	}
	return nil
}

func (store *PendingRegistrationStore) validate() error {
	if store == nil || store.client == nil {
		return errors.New("pending registration store is not configured")
	}
	return nil
}

func pendingKey(email string) string {
	return "auth:registration:pending:" + strings.ToLower(strings.TrimSpace(email))
}
