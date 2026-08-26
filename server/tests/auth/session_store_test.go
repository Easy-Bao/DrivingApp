package auth_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

type testRefreshSessionStore struct {
	mu       sync.Mutex
	sessions map[string]testRefreshSession
}

type testRefreshSession struct {
	session   domain.RefreshSession
	revokedAt *time.Time
}

func newTestRefreshSessionStore() *testRefreshSessionStore {
	return &testRefreshSessionStore{sessions: make(map[string]testRefreshSession)}
}

func (store *testRefreshSessionStore) Create(_ context.Context, session domain.RefreshSession) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	if _, exists := store.sessions[session.TokenHash]; exists {
		return fmt.Errorf("refresh session already exists")
	}
	store.sessions[session.TokenHash] = testRefreshSession{session: session}
	return nil
}

func (store *testRefreshSessionStore) FindActive(_ context.Context, tokenHash string, now time.Time) (domain.RefreshSession, error) {
	store.mu.Lock()
	defer store.mu.Unlock()
	item, exists := store.sessions[tokenHash]
	if !exists || item.revokedAt != nil || !item.session.ExpiresAt.After(now) {
		return domain.RefreshSession{}, domain.ErrInvalidRefreshToken
	}
	return item.session, nil
}

func (store *testRefreshSessionStore) Rotate(_ context.Context, tokenHash string, replacement domain.RefreshSession, now time.Time) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	item, exists := store.sessions[tokenHash]
	if !exists || item.revokedAt != nil || !item.session.ExpiresAt.After(now) || item.session.UserID != replacement.UserID {
		return domain.ErrInvalidRefreshToken
	}
	if _, exists := store.sessions[replacement.TokenHash]; exists {
		return errors.New("replacement refresh session already exists")
	}
	revokedAt := now
	item.revokedAt = &revokedAt
	store.sessions[tokenHash] = item
	store.sessions[replacement.TokenHash] = testRefreshSession{session: replacement}
	return nil
}

func (store *testRefreshSessionStore) Revoke(_ context.Context, tokenHash string, now time.Time) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	item, exists := store.sessions[tokenHash]
	if !exists || item.revokedAt != nil {
		return nil
	}
	revokedAt := now
	item.revokedAt = &revokedAt
	store.sessions[tokenHash] = item
	return nil
}

func (store *testRefreshSessionStore) RevokeAll(_ context.Context, userID int, now time.Time) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	for tokenHash, item := range store.sessions {
		if item.session.UserID != userID || item.revokedAt != nil {
			continue
		}
		revokedAt := now
		item.revokedAt = &revokedAt
		store.sessions[tokenHash] = item
	}
	return nil
}
