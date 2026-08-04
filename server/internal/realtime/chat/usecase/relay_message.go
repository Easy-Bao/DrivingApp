package usecase

import "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"

type Service struct{ publisher domain.Publisher }

func NewService(publisher domain.Publisher) *Service { return &Service{publisher: publisher} }
func (service *Service) Relay(message domain.Message) error {
	return service.publisher.Publish(message)
}
