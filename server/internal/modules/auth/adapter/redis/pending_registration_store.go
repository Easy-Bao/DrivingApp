package redis

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	authports "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
	redisclient "github.com/redis/go-redis/v9"
)

type PendingRegistrationStore struct{ client *redisclient.Client }

var _ authports.PendingRegistrationStore = (*PendingRegistrationStore)(nil)

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
	payload, err := encodePendingRegistration(registration)
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
	registration, err := decodePendingRegistration(payload)
	if err != nil {
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

type pendingRegistrationRecord struct {
	Email        string      `json:"email"`
	Phone        string      `json:"phone"`
	Name         string      `json:"name"`
	PasswordHash string      `json:"password_hash"`
	Role         domain.Role `json:"role"`
	VehicleType  string      `json:"vehicle_type,omitempty"`
	PlateNumber  string      `json:"plate_number,omitempty"`
}

func encodePendingRegistration(registration domain.PendingRegistration) ([]byte, error) {
	return json.Marshal(pendingRegistrationRecord{
		Email:        registration.Email,
		Phone:        registration.Phone,
		Name:         registration.Name,
		PasswordHash: registration.PasswordHash,
		Role:         registration.Role,
		VehicleType:  registration.VehicleType,
		PlateNumber:  registration.PlateNumber,
	})
}

func decodePendingRegistration(payload []byte) (domain.PendingRegistration, error) {
	var record pendingRegistrationRecord
	if err := json.Unmarshal(payload, &record); err != nil {
		return domain.PendingRegistration{}, err
	}
	return domain.PendingRegistration{
		Email:        record.Email,
		Phone:        record.Phone,
		Name:         record.Name,
		PasswordHash: record.PasswordHash,
		Role:         record.Role,
		VehicleType:  record.VehicleType,
		PlateNumber:  record.PlateNumber,
	}, nil
}
