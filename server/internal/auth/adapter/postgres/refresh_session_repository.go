package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/refreshsession"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

// RefreshSessionRepository persists only server-side refresh-token digests.
// The opaque token itself never crosses this adapter boundary.
type RefreshSessionRepository struct {
	client *ent.Client
}

func NewRefreshSessionRepository(client *ent.Client) *RefreshSessionRepository {
	return &RefreshSessionRepository{client: client}
}

func (repository *RefreshSessionRepository) Create(ctx context.Context, session domain.RefreshSession) error {
	_, err := repository.client.RefreshSession.Create().
		SetUserID(session.UserID).
		SetTokenHash(session.TokenHash).
		SetExpiresAt(session.ExpiresAt).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("create refresh session: %w", err)
	}
	return nil
}

func (repository *RefreshSessionRepository) FindActive(ctx context.Context, tokenHash string, now time.Time) (domain.RefreshSession, error) {
	session, err := repository.client.RefreshSession.Query().
		Where(
			refreshsession.TokenHashEQ(tokenHash),
			refreshsession.RevokedAtIsNil(),
			refreshsession.ExpiresAtGT(now),
		).
		Only(ctx)
	if ent.IsNotFound(err) {
		return domain.RefreshSession{}, domain.ErrInvalidRefreshToken
	}
	if err != nil {
		return domain.RefreshSession{}, fmt.Errorf("find active refresh session: %w", err)
	}
	return toDomainRefreshSession(session), nil
}

func (repository *RefreshSessionRepository) Rotate(ctx context.Context, tokenHash string, replacement domain.RefreshSession, now time.Time) error {
	transaction, err := repository.client.Tx(ctx)
	if err != nil {
		return fmt.Errorf("begin refresh session rotation: %w", err)
	}
	defer transaction.Rollback()

	current, err := transaction.RefreshSession.Query().
		Where(
			refreshsession.TokenHashEQ(tokenHash),
			refreshsession.RevokedAtIsNil(),
			refreshsession.ExpiresAtGT(now),
		).
		ForUpdate().
		Only(ctx)
	if ent.IsNotFound(err) {
		return domain.ErrInvalidRefreshToken
	}
	if err != nil {
		return fmt.Errorf("load refresh session for rotation: %w", err)
	}
	if current.UserID != replacement.UserID {
		return domain.ErrInvalidRefreshToken
	}

	if _, err := current.Update().SetRevokedAt(now).SetLastUsedAt(now).Save(ctx); err != nil {
		return fmt.Errorf("revoke refresh session during rotation: %w", err)
	}
	if _, err := transaction.RefreshSession.Create().
		SetUserID(replacement.UserID).
		SetTokenHash(replacement.TokenHash).
		SetExpiresAt(replacement.ExpiresAt).
		Save(ctx); err != nil {
		return fmt.Errorf("create replacement refresh session: %w", err)
	}
	if err := transaction.Commit(); err != nil {
		return fmt.Errorf("commit refresh session rotation: %w", err)
	}
	return nil
}

func (repository *RefreshSessionRepository) Revoke(ctx context.Context, tokenHash string, now time.Time) error {
	_, err := repository.client.RefreshSession.Update().
		Where(
			refreshsession.TokenHashEQ(tokenHash),
			refreshsession.RevokedAtIsNil(),
		).
		SetRevokedAt(now).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("revoke refresh session: %w", err)
	}
	return nil
}

func (repository *RefreshSessionRepository) RevokeAll(ctx context.Context, userID int, now time.Time) error {
	_, err := repository.client.RefreshSession.Update().
		Where(
			refreshsession.UserIDEQ(userID),
			refreshsession.RevokedAtIsNil(),
		).
		SetRevokedAt(now).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("revoke user refresh sessions: %w", err)
	}
	return nil
}

func toDomainRefreshSession(session *ent.RefreshSession) domain.RefreshSession {
	return domain.RefreshSession{
		UserID:    session.UserID,
		TokenHash: session.TokenHash,
		ExpiresAt: session.ExpiresAt,
	}
}
