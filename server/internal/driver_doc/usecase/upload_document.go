package usecase

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/domain"
)

type Service struct {
	repository domain.Repository
	storage    domain.Storage
}

func NewService(repository domain.Repository, storage domain.Storage) *Service {
	return &Service{repository: repository, storage: storage}
}
func (service *Service) Upload(ctx context.Context, driverID int, documentType string, content []byte) (domain.Document, error) {
	key, err := service.storage.Put(ctx, driverID, documentType, content)
	if err != nil {
		return domain.Document{}, err
	}
	return service.repository.Create(ctx, domain.Document{DriverID: driverID, Type: documentType, StorageKey: key, Status: domain.Pending})
}
func (service *Service) Status(ctx context.Context, driverID int) ([]domain.Document, error) {
	return service.repository.List(ctx, driverID)
}
func (service *Service) Review(ctx context.Context, id int, status domain.Status) (domain.Document, error) {
	return service.repository.Review(ctx, id, status)
}
