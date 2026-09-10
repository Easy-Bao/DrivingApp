package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// RefreshSessionRepository stores only refresh-token digests and keeps
// rotation atomic through a PostgreSQL row lock.
type RefreshSessionRepository struct {
	pool    *pgxpool.Pool
	queries *databasepostgres.Queries
}

var _ authports.SessionStore = (*RefreshSessionRepository)(nil)

func NewRefreshSessionRepository(pool *pgxpool.Pool) (*RefreshSessionRepository, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &RefreshSessionRepository{
		pool:    pool,
		queries: databasepostgres.New(pool),
	}, nil
}

// SessionStore is the canonical adapter name used by the auth composition
// root. The repository constructor remains for existing internal callers.
type SessionStore = RefreshSessionRepository

func NewSessionStore(pool *pgxpool.Pool) (*SessionStore, error) {
	return NewRefreshSessionRepository(pool)
}

func (repository *RefreshSessionRepository) Create(ctx context.Context, session domain.RefreshSession) error {
	if err := repository.validate(); err != nil {
		return err
	}
	userID, err := toPostgresUserID(session.UserID)
	if err != nil {
		return err
	}
	if err := repository.queries.CreateRefreshSession(ctx, databasepostgres.CreateRefreshSessionParams{
		UserID:    userID,
		TokenHash: session.TokenHash,
		ExpiresAt: toPostgresTimestamp(session.ExpiresAt),
	}); err != nil {
		return fmt.Errorf("create refresh session: %w", err)
	}
	return nil
}

func (repository *RefreshSessionRepository) FindActive(ctx context.Context, tokenHash string, now time.Time) (domain.RefreshSession, error) {
	if err := repository.validate(); err != nil {
		return domain.RefreshSession{}, err
	}
	row, err := repository.queries.GetActiveRefreshSession(ctx, databasepostgres.GetActiveRefreshSessionParams{
		TokenHash: tokenHash,
		ExpiresAt: toPostgresTimestamp(now),
	})
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.RefreshSession{}, domain.ErrInvalidRefreshToken
	}
	if err != nil {
		return domain.RefreshSession{}, fmt.Errorf("find active refresh session: %w", err)
	}
	return fromPostgresRefreshSession(row.UserID, row.TokenHash, row.ExpiresAt)
}

func (repository *RefreshSessionRepository) Rotate(ctx context.Context, tokenHash string, replacement domain.RefreshSession, now time.Time) error {
	if err := repository.validate(); err != nil {
		return err
	}
	replacementUserID, err := toPostgresUserID(replacement.UserID)
	if err != nil {
		return err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin refresh session rotation: %w", err)
	}
	defer func() {
		_ = transaction.Rollback(ctx)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	current, err := transactionQueries.GetActiveRefreshSessionForUpdate(ctx, databasepostgres.GetActiveRefreshSessionForUpdateParams{
		TokenHash: tokenHash,
		ExpiresAt: toPostgresTimestamp(now),
	})
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.ErrInvalidRefreshToken
	}
	if err != nil {
		return fmt.Errorf("load refresh session for rotation: %w", err)
	}
	if current.UserID != replacementUserID {
		return domain.ErrInvalidRefreshToken
	}

	rows, err := transactionQueries.RevokeRefreshSessionByID(ctx, databasepostgres.RevokeRefreshSessionByIDParams{
		ID:        current.ID,
		RevokedAt: toPostgresTimestamp(now),
	})
	if err != nil {
		return fmt.Errorf("revoke refresh session during rotation: %w", err)
	}
	if rows != 1 {
		return fmt.Errorf("revoke refresh session during rotation: %w", pgx.ErrNoRows)
	}

	if err := transactionQueries.CreateRefreshSession(ctx, databasepostgres.CreateRefreshSessionParams{
		UserID:    replacementUserID,
		TokenHash: replacement.TokenHash,
		ExpiresAt: toPostgresTimestamp(replacement.ExpiresAt),
	}); err != nil {
		return fmt.Errorf("create replacement refresh session: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return fmt.Errorf("commit refresh session rotation: %w", err)
	}
	return nil
}

func (repository *RefreshSessionRepository) Revoke(ctx context.Context, tokenHash string, now time.Time) error {
	if err := repository.validate(); err != nil {
		return err
	}
	if err := repository.queries.RevokeRefreshSession(ctx, databasepostgres.RevokeRefreshSessionParams{
		TokenHash: tokenHash,
		RevokedAt: toPostgresTimestamp(now),
	}); err != nil {
		return fmt.Errorf("revoke refresh session: %w", err)
	}
	return nil
}

func (repository *RefreshSessionRepository) RevokeAll(ctx context.Context, userID int, now time.Time) error {
	if err := repository.validate(); err != nil {
		return err
	}
	dbUserID, err := toPostgresUserID(userID)
	if err != nil {
		return err
	}
	if err := repository.queries.RevokeUserRefreshSessions(ctx, databasepostgres.RevokeUserRefreshSessionsParams{
		UserID:    dbUserID,
		RevokedAt: toPostgresTimestamp(now),
	}); err != nil {
		return fmt.Errorf("revoke user refresh sessions: %w", err)
	}
	return nil
}

func (repository *RefreshSessionRepository) validate() error {
	if repository == nil || repository.pool == nil || repository.queries == nil {
		return errors.New("postgresql refresh session repository is not initialized")
	}
	return nil
}

func fromPostgresRefreshSession(userID int32, tokenHash string, expiresAt pgtype.Timestamptz) (domain.RefreshSession, error) {
	if !expiresAt.Valid {
		return domain.RefreshSession{}, errors.New("refresh session expiry is null")
	}
	return domain.RefreshSession{
		UserID:    int(userID),
		TokenHash: tokenHash,
		ExpiresAt: expiresAt.Time,
	}, nil
}

func toPostgresTimestamp(value time.Time) pgtype.Timestamptz {
	return pgtype.Timestamptz{Time: value, Valid: true}
}
