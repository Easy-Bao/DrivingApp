package postgres

import (
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

func TestNewPostgresRefreshSessionRepositoryRejectsNilPool(t *testing.T) {
	if _, err := NewPostgresRefreshSessionRepository(nil); err == nil {
		t.Fatal("expected nil PostgreSQL pool to be rejected")
	}
}

func TestFromPostgresRefreshSessionMapsTimestamp(t *testing.T) {
	expiresAt := time.Date(2026, time.September, 7, 12, 30, 0, 0, time.UTC)
	session, err := fromPostgresRefreshSession(7, "hash", pgtype.Timestamptz{Time: expiresAt, Valid: true})
	if err != nil {
		t.Fatalf("fromPostgresRefreshSession() error = %v", err)
	}
	if session.UserID != 7 || session.TokenHash != "hash" || !session.ExpiresAt.Equal(expiresAt) {
		t.Fatalf("mapped session = %+v", session)
	}
}

func TestFromPostgresRefreshSessionRejectsNullExpiry(t *testing.T) {
	_, err := fromPostgresRefreshSession(7, "hash", pgtype.Timestamptz{})
	if err == nil {
		t.Fatal("expected null expiry to be rejected")
	}
}
