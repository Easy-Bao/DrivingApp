package application

import (
	"context"
	"errors"
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

type ProfileService struct{ repository domain.Repository }

func NewProfileService(repository domain.Repository) *ProfileService {
	return &ProfileService{repository: repository}
}
func (service *ProfileService) Get(ctx context.Context, userID int) (domain.Profile, error) {
	return service.repository.Get(ctx, userID)
}
func (service *ProfileService) Update(ctx context.Context, profile domain.Profile) (domain.Profile, error) {
	return service.repository.Save(ctx, profile)
}

func (service *ProfileService) MaxAvatarBytes() int64 {
	return domain.MaxAvatarBytes
}

func (service *ProfileService) SaveAvatar(ctx context.Context, userID int, content []byte) (domain.Profile, error) {
	if userID <= 0 || len(content) == 0 || int64(len(content)) > domain.MaxAvatarBytes {
		return domain.Profile{}, domain.ErrInvalidAvatar
	}
	contentType := http.DetectContentType(content)
	if contentType != "image/jpeg" && contentType != "image/png" {
		return domain.Profile{}, domain.ErrInvalidAvatar
	}
	repository, ok := service.repository.(domain.AvatarRepository)
	if !ok {
		return domain.Profile{}, domain.ErrAvatarStorageUnavailable
	}
	return repository.SaveAvatar(ctx, userID, content, contentType)
}

func (service *ProfileService) Avatar(ctx context.Context, userID int) (domain.Avatar, error) {
	if userID <= 0 {
		return domain.Avatar{}, domain.ErrAvatarNotFound
	}
	repository, ok := service.repository.(domain.AvatarRepository)
	if !ok {
		return domain.Avatar{}, domain.ErrAvatarStorageUnavailable
	}
	return repository.GetAvatar(ctx, userID)
}

func (service *ProfileService) Notifications(ctx context.Context, userID, limit, offset int) ([]domain.Notification, error) {
	repository, ok := service.repository.(domain.NotificationRepository)
	if !ok {
		return []domain.Notification{}, nil
	}
	if limit <= 0 || limit > 100 || offset < 0 || offset > 1_000_000 {
		return nil, errors.New("notification pagination is invalid")
	}
	return repository.Notifications(ctx, userID, limit, offset)
}
