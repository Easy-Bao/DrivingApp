package usecase

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
)

type Service struct {
	publisher domain.Publisher
	history   domain.HistoryRepository
}

func NewService(publisher domain.Publisher, history ...domain.HistoryRepository) *Service {
	var repository domain.HistoryRepository
	if len(history) > 0 {
		repository = history[0]
	}
	return &Service{publisher: publisher, history: repository}
}
func (service *Service) Relay(message domain.Message) error {
	if service.history != nil {
		if err := service.history.Append(context.Background(), message); err != nil {
			return err
		}
	}
	return service.publisher.Publish(message)
}

func (service *Service) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	if service.history == nil {
		return nil
	}
	return service.history.CreateRoom(ctx, roomID, passengerID, driverID)
}

func (service *Service) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	if service.history == nil {
		return []domain.Message{}, nil
	}
	return service.history.Messages(ctx, roomID)
}

func (service *Service) Resolve(ctx context.Context, roomID string) error {
	if service.history == nil {
		return nil
	}
	return service.history.Resolve(ctx, roomID)
}
