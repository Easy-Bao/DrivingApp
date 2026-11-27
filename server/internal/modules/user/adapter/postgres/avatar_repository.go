package postgres

import (
	"context"
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"net/http"
	"strings"
	"time"
)

func (repository *ProfileRepository) SaveAvatar(
	ctx context.Context,
	userID int,
	content []byte,
	contentType string,
) (domain.Profile, error) {
	if err := repository.validate(); err != nil {
		return domain.Profile{}, fmt.Errorf("validate profile repository: %w", err)
	}
	if repository.avatarStorage == nil {
		return domain.Profile{}, domain.ErrAvatarStorageUnavailable
	}
	dbUserID, err := pgutil.ToPositiveInt32(userID, "user id")
	if err != nil {
		return domain.Profile{}, fmt.Errorf("convert profile user id: %w", err)
	}

	_, err = repository.queries.GetPassengerProfileByUserIDFull(ctx, dbUserID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Profile{}, domain.ErrAvatarNotFound
	}
	if err != nil {
		return domain.Profile{}, fmt.Errorf("find passenger avatar profile: %w", err)
	}

	storageKey, err := repository.avatarStorage.Store(ctx, content)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("store passenger avatar: %w", err)
	}

	committed := false
	defer func() {
		if !committed {
			repository.cleanupAvatar(ctx, storageKey)
		}
	}()

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("begin passenger avatar transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	passengerProfile, err := transactionQueries.LockPassengerProfileByUserID(ctx, dbUserID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Profile{}, domain.ErrAvatarNotFound
	}
	if err != nil {
		return domain.Profile{}, fmt.Errorf("lock passenger avatar profile: %w", err)
	}

	updatedRows, err := transactionQueries.UpdatePassengerAvatar(ctx, databasepostgres.UpdatePassengerAvatarParams{
		ID:                passengerProfile.ID,
		UserID:            dbUserID,
		AvatarStorageKey:  pgutil.ToText(storageKey),
		AvatarContentType: pgutil.ToText(contentType),
	})
	if err != nil {
		return domain.Profile{}, fmt.Errorf("update passenger avatar metadata: %w", err)
	}
	if updatedRows == 0 {
		return domain.Profile{}, domain.ErrAvatarNotFound
	}

	if err := transaction.Commit(ctx); err != nil {
		return domain.Profile{}, fmt.Errorf("commit passenger avatar transaction: %w", err)
	}
	committed = true

	oldStorageKey := strings.TrimSpace(pgutil.TextValue(passengerProfile.AvatarStorageKey))
	if oldStorageKey != "" && oldStorageKey != storageKey {
		repository.cleanupAvatar(ctx, oldStorageKey)
	}
	return repository.Get(ctx, userID)
}

func (repository *ProfileRepository) cleanupAvatar(ctx context.Context, storageKey string) {
	cleanupContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), time.Second)
	defer cancel()
	if err := repository.avatarStorage.Delete(cleanupContext, storageKey); err != nil {
		repository.log().WarnContext(ctx, "delete passenger avatar object failed", "error", err, "operation", "delete", "storage_key", storageKey)
	}
}

func (repository *ProfileRepository) GetAvatar(ctx context.Context, userID int) (domain.Avatar, error) {
	if err := repository.validate(); err != nil {
		return domain.Avatar{}, fmt.Errorf("validate profile repository: %w", err)
	}
	if repository.avatarStorage == nil {
		return domain.Avatar{}, domain.ErrAvatarStorageUnavailable
	}
	dbUserID, err := pgutil.ToPositiveInt32(userID, "user id")
	if err != nil {
		return domain.Avatar{}, fmt.Errorf("convert profile user id: %w", err)
	}

	passengerProfile, err := repository.queries.GetPassengerProfileByUserIDFull(ctx, dbUserID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Avatar{}, domain.ErrAvatarNotFound
	}
	if err != nil {
		return domain.Avatar{}, fmt.Errorf("find passenger avatar profile: %w", err)
	}
	storageKey := strings.TrimSpace(pgutil.TextValue(passengerProfile.AvatarStorageKey))
	if storageKey == "" {
		return domain.Avatar{}, domain.ErrAvatarNotFound
	}

	content, err := repository.avatarStorage.Read(ctx, storageKey, domain.MaxAvatarBytes)
	if err != nil {
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			return domain.Avatar{}, fmt.Errorf("read passenger avatar: %w", err)
		}
		return domain.Avatar{}, errors.Join(
			domain.ErrAvatarCorrupt,
			fmt.Errorf("read passenger avatar: %w", err),
		)
	}
	contentType := http.DetectContentType(content)
	storedContentType := strings.TrimSpace(pgutil.TextValue(passengerProfile.AvatarContentType))
	invalidContentType := contentType != "image/jpeg" && contentType != "image/png"
	contentTypeMismatch := storedContentType != "" && storedContentType != contentType
	if invalidContentType || contentTypeMismatch {
		return domain.Avatar{}, domain.ErrAvatarCorrupt
	}
	return domain.Avatar{Bytes: content, ContentType: contentType}, nil
}
