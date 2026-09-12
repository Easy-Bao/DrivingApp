package application

import (
	"context"
	"errors"
	"fmt"
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/user/ports"
)

type ProfileService struct{ repository ports.ProfileStore }

var (
	ErrProfileUnavailable      = errors.New("profile persistence is unavailable")
	ErrNotificationUnavailable = errors.New("notification persistence is unavailable")
)

func NewProfileService(repository ports.ProfileStore) *ProfileService {
	return &ProfileService{repository: repository}
}
func (service *ProfileService) Get(ctx context.Context, userID int) (domain.Profile, error) {
	if service.repository == nil {
		return domain.Profile{}, ErrProfileUnavailable
	}
	profile, err := service.repository.Get(ctx, userID)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("load profile: %w", err)
	}
	return profile, nil
}
func (service *ProfileService) Update(ctx context.Context, profile domain.Profile) (domain.Profile, error) {
	if service.repository == nil {
		return domain.Profile{}, ErrProfileUnavailable
	}
	updated, err := service.repository.Save(ctx, profile)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("save profile: %w", err)
	}
	return updated, nil
}

func (service *ProfileService) MaxAvatarBytes() int64 {
	return domain.MaxAvatarBytes
}

func (service *ProfileService) SaveAvatar(ctx context.Context, userID int, content []byte) (domain.Profile, error) {
	invalidUserID := userID <= 0
	invalidSize := len(content) == 0 || int64(len(content)) > domain.MaxAvatarBytes
	if invalidUserID || invalidSize {
		return domain.Profile{}, domain.ErrInvalidAvatar
	}
	contentType := http.DetectContentType(content)
	if contentType != "image/jpeg" && contentType != "image/png" {
		return domain.Profile{}, domain.ErrInvalidAvatar
	}
	repository, ok := service.repository.(ports.AvatarStore)
	if !ok {
		return domain.Profile{}, domain.ErrAvatarStorageUnavailable
	}
	profile, err := repository.SaveAvatar(ctx, userID, content, contentType)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("save profile avatar: %w", err)
	}
	return profile, nil
}

func (service *ProfileService) Avatar(ctx context.Context, userID int) (domain.Avatar, error) {
	if userID <= 0 {
		return domain.Avatar{}, domain.ErrAvatarNotFound
	}
	repository, ok := service.repository.(ports.AvatarStore)
	if !ok {
		return domain.Avatar{}, domain.ErrAvatarStorageUnavailable
	}
	avatar, err := repository.GetAvatar(ctx, userID)
	if err != nil {
		return domain.Avatar{}, fmt.Errorf("load profile avatar: %w", err)
	}
	return avatar, nil
}

func (service *ProfileService) Notifications(
	ctx context.Context,
	userID int,
	limit int,
	offset int,
) ([]domain.Notification, error) {
	repository, ok := service.repository.(ports.NotificationStore)
	if !ok {
		return nil, ErrNotificationUnavailable
	}
	if userID <= 0 {
		return nil, errors.New("notification user id is invalid")
	}
	invalidLimit := limit <= 0 || limit > 100
	invalidOffset := offset < 0 || offset > 1_000_000
	if invalidLimit || invalidOffset {
		return nil, errors.New("notification pagination is invalid")
	}
	items, err := repository.Notifications(ctx, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("load notifications: %w", err)
	}
	return items, nil
}

func (service *ProfileService) DeleteNotification(
	ctx context.Context,
	userID int,
	notificationID int,
) error {
	repository, ok := service.repository.(ports.NotificationStore)
	if !ok {
		return ErrNotificationUnavailable
	}
	if userID <= 0 || notificationID <= 0 {
		return errors.New("notification identity is invalid")
	}
	if err := repository.DeleteNotification(ctx, userID, notificationID); err != nil {
		return fmt.Errorf("delete notification: %w", err)
	}
	return nil
}
