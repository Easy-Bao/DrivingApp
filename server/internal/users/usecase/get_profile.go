package usecase

import (
	"context"
	"errors"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/domain"
)

type Service struct{ repository domain.Repository }

func NewService(repository domain.Repository) *Service { return &Service{repository: repository} }
func (service *Service) Get(ctx context.Context, userID int) (domain.Profile, error) {
	return service.repository.Get(ctx, userID)
}
func (service *Service) Update(ctx context.Context, profile domain.Profile) (domain.Profile, error) {
	return service.repository.Save(ctx, profile)
}

func (service *Service) Notifications(ctx context.Context, userID, limit, offset int) ([]domain.Notification, error) {
	repository, ok := service.repository.(domain.NotificationRepository)
	if !ok {
		return []domain.Notification{}, nil
	}
	if limit <= 0 || limit > 100 || offset < 0 || offset > 1_000_000 {
		return nil, errors.New("notification pagination is invalid")
	}
	return repository.Notifications(ctx, userID, limit, offset)
}
