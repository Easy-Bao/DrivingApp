package postgres

import (
	"context"
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"math"
)

func (repository *ProfileRepository) Notifications(
	ctx context.Context,
	userID int,
	limit int,
	offset int,
) ([]domain.Notification, error) {
	if err := repository.validate(); err != nil {
		return nil, fmt.Errorf("validate profile repository: %w", err)
	}
	dbUserID, err := pgutil.ToPositiveInt32(userID, "user id")
	if err != nil {
		return nil, fmt.Errorf("convert notification user id: %w", err)
	}
	if limit <= 0 {
		return nil, errors.New("notification limit must be positive")
	}
	if limit == math.MaxInt {
		return nil, errors.New("notification limit exceeds native integer range")
	}
	dbLimit, err := pgutil.ToNonNegativeInt32(limit+1, "limit")
	if err != nil {
		return nil, fmt.Errorf("convert notification limit: %w", err)
	}
	dbOffset, err := pgutil.ToNonNegativeInt32(offset, "offset")
	if err != nil {
		return nil, fmt.Errorf("convert notification offset: %w", err)
	}

	items, err := repository.queries.ListNotifications(ctx, databasepostgres.ListNotificationsParams{
		UserID: dbUserID,
		Limit:  dbLimit,
		Offset: dbOffset,
	})
	if err != nil {
		return nil, fmt.Errorf("list notifications: %w", err)
	}
	result := make([]domain.Notification, 0, len(items))
	for _, item := range items {
		notification, mappingErr := fromPostgresNotification(item)
		if mappingErr != nil {
			return nil, fmt.Errorf("map notification: %w", mappingErr)
		}
		result = append(result, notification)
	}
	return result, nil
}

func (repository *ProfileRepository) MarkAllNotificationsRead(ctx context.Context, userID int) error {
	if err := repository.validate(); err != nil {
		return fmt.Errorf("validate profile repository: %w", err)
	}
	dbUserID, err := pgutil.ToPositiveInt32(userID, "user id")
	if err != nil {
		return fmt.Errorf("convert notification user id: %w", err)
	}
	if err := repository.queries.MarkAllNotificationsRead(ctx, dbUserID); err != nil {
		return fmt.Errorf("mark all notifications read: %w", err)
	}
	return nil
}

func (repository *ProfileRepository) DeleteNotification(
	ctx context.Context,
	userID int,
	notificationID int,
) error {
	if err := repository.validate(); err != nil {
		return fmt.Errorf("validate profile repository: %w", err)
	}
	dbUserID, err := pgutil.ToPositiveInt32(userID, "user id")
	if err != nil {
		return fmt.Errorf("convert notification user id: %w", err)
	}
	dbNotificationID, err := pgutil.ToPositiveInt32(notificationID, "notification id")
	if err != nil {
		return fmt.Errorf("convert notification id: %w", err)
	}
	deleted, err := repository.queries.DeleteNotification(ctx, databasepostgres.DeleteNotificationParams{
		ID:     dbNotificationID,
		UserID: dbUserID,
	})
	if err != nil {
		return fmt.Errorf("delete notification: %w", err)
	}
	if deleted == 0 {
		return domain.ErrNotificationNotFound
	}
	return nil
}
