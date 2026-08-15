package postgres

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverdocument"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
)

type Repository struct{ client *ent.Client }

func NewRepository(client *ent.Client) *Repository { return &Repository{client: client} }
func (repository *Repository) Create(ctx context.Context, item domain.Document) (domain.Document, error) {
	created, err := repository.client.DriverDocument.Create().SetDriverID(item.DriverID).SetDocumentType(item.Type).SetStorageKey(item.StorageKey).SetStatus(string(item.Status)).Save(ctx)
	if err != nil {
		return domain.Document{}, err
	}
	return fromEnt(created), nil
}
func (repository *Repository) List(ctx context.Context, driverID int) ([]domain.Document, error) {
	items, err := repository.client.DriverDocument.Query().Where(driverdocument.DriverIDEQ(driverID)).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Document, 0, len(items))
	for _, item := range items {
		result = append(result, fromEnt(item))
	}
	return result, nil
}
func (repository *Repository) Review(ctx context.Context, id int, status domain.Status) (domain.Document, error) {
	item, err := repository.client.DriverDocument.UpdateOneID(id).SetStatus(string(status)).Save(ctx)
	if err != nil {
		return domain.Document{}, err
	}
	return fromEnt(item), nil
}
func fromEnt(item *ent.DriverDocument) domain.Document {
	return domain.Document{ID: item.ID, DriverID: item.DriverID, Type: item.DocumentType, StorageKey: item.StorageKey, Status: domain.Status(item.Status)}
}
