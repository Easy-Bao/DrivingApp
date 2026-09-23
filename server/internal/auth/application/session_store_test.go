package application_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/session"
)

type testRefreshSessionStore struct {
	mu       sync.Mutex
	sessions map[string]testRefreshSession
}

type testRefreshSession struct {
	session            domain.RefreshSession
	revokedAt          *time.Time
	rotationGraceUntil *time.Time
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

func (store *testRefreshSessionStore) FindActive(
	_ context.Context,
	tokenHash string,
	now time.Time,
) (domain.RefreshSession, error) {
	store.mu.Lock()
	defer store.mu.Unlock()
	item, exists := store.sessions[tokenHash]
	graceExpired := item.revokedAt != nil &&
		(item.rotationGraceUntil == nil || now.After(*item.rotationGraceUntil))
	if !exists || graceExpired || !item.session.ExpiresAt.After(now) {
		return domain.RefreshSession{}, domain.ErrInvalidRefreshToken
	}
	return item.session, nil
}

func (store *testRefreshSessionStore) Rotate(
	_ context.Context,
	tokenHash string,
	replacement domain.RefreshSession,
	now time.Time,
) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	item, exists := store.sessions[tokenHash]
	missingSession := !exists
	revoked := item.revokedAt != nil
	expired := !item.session.ExpiresAt.After(now)
	wrongUser := item.session.UserID != replacement.UserID
	graceExpired := revoked &&
		(item.rotationGraceUntil == nil || now.After(*item.rotationGraceUntil))
	if missingSession || graceExpired || expired || wrongUser {
		return domain.ErrInvalidRefreshToken
	}
	if _, exists := store.sessions[replacement.TokenHash]; exists {
		return errors.New("replacement refresh session already exists")
	}
	revokedAt := now
	item.revokedAt = &revokedAt
	if item.rotationGraceUntil == nil {
		graceUntil := now.Add(session.RefreshTokenRotationGracePeriod)
		item.rotationGraceUntil = &graceUntil
	}
	store.sessions[tokenHash] = item
	store.sessions[replacement.TokenHash] = testRefreshSession{session: replacement}
	return nil
}

func (store *testRefreshSessionStore) Revoke(_ context.Context, tokenHash string, now time.Time) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	item, exists := store.sessions[tokenHash]
	graceActive := item.revokedAt != nil && item.rotationGraceUntil != nil &&
		now.Before(*item.rotationGraceUntil)
	if !exists || (item.revokedAt != nil && !graceActive) {
		return nil
	}
	revokedAt := now
	item.revokedAt = &revokedAt
	item.rotationGraceUntil = nil
	store.sessions[tokenHash] = item
	return nil
}

func (store *testRefreshSessionStore) RevokeAll(_ context.Context, userID int, now time.Time) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	for tokenHash, item := range store.sessions {
		graceActive := item.revokedAt != nil && item.rotationGraceUntil != nil &&
			now.Before(*item.rotationGraceUntil)
		if item.session.UserID != userID || (item.revokedAt != nil && !graceActive) {
			continue
		}
		revokedAt := now
		item.revokedAt = &revokedAt
		item.rotationGraceUntil = nil
		store.sessions[tokenHash] = item
	}
	return nil
}
