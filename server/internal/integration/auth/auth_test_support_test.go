//go:build integration

package auth_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
	"golang.org/x/crypto/bcrypt"
)

type repository struct {
	users map[string]domain.User
	next  int
}

func (repository *repository) Create(_ context.Context, account domain.User) (domain.User, error) {
	repository.next++
	account.ID = repository.next
	repository.users[account.Email] = account
	return account, nil
}

func (repository *repository) FindByEmail(_ context.Context, email string) (domain.User, error) {
	return repository.users[email], nil
}

func (repository *repository) FindByID(_ context.Context, id int) (domain.User, error) {
	for _, account := range repository.users {
		if account.ID == id {
			return account, nil
		}
	}
	return domain.User{}, nil
}

func (repository *repository) UpdatePassword(_ context.Context, id int, passwordHash string) error {
	for email, account := range repository.users {
		if account.ID == id {
			account.PasswordHash = passwordHash
			repository.users[email] = account
		}
	}
	return nil
}

func (repository *repository) MarkVerified(_ context.Context, id int) error {
	for email, account := range repository.users {
		if account.ID == id {
			account.IsVerified = true
			repository.users[email] = account
			return nil
		}
	}
	return domain.ErrUserNotFound
}

type resetOTPStore struct {
	code     string
	attempts int64
}

var _ authports.OTPStore = (*resetOTPStore)(nil)

func (store *resetOTPStore) Put(_ context.Context, _, _, code string, _ time.Duration) error {
	store.code = code
	store.attempts = 0
	return nil
}

func (store *resetOTPStore) Consume(_ context.Context, _, _, code string) error {
	if store.code == "" {
		return domain.ErrInvalidOTP
	}
	if code != store.code {
		store.attempts++
		if store.attempts >= domain.MaxOTPVerificationAttempts {
			store.code = ""
			return domain.ErrOTPMaxAttemptsExceeded
		}
		return domain.ErrInvalidOTP
	}
	store.code = ""
	store.attempts = 0
	return nil
}

type issuer struct{}

func (issuer) Issue(subject string) (string, error) { return "token:" + subject, nil }

func testPasswordHash(t *testing.T, password string) string {
	t.Helper()
	hash, err := testHashPassword(password)
	if err != nil {
		t.Fatalf("hash test password: %v", err)
	}
	return hash
}

func testHashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.MinCost)
	return string(hash), err
}

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

func (store *testRefreshSessionStore) FindActive(
	_ context.Context,
	tokenHash string,
	now time.Time,
) (domain.RefreshSession, error) {
	store.mu.Lock()
	defer store.mu.Unlock()
	item, exists := store.sessions[tokenHash]
	if !exists || item.revokedAt != nil || !item.session.ExpiresAt.After(now) {
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
	if missingSession || revoked || expired || wrongUser {
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
