package postgres

import (
	"context"
	"time"

	entsql "entgo.io/ent/dialect/sql"
	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverdocument"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
)

type Repository struct{ client *ent.Client }

func NewRepository(client *ent.Client) *Repository { return &Repository{client: client} }
func (repository *Repository) Create(ctx context.Context, item domain.Document) (domain.Document, error) {
	created, err := repository.client.DriverDocument.Create().
		SetDriverID(item.DriverID).
		SetDocumentType(string(item.Type)).
		SetStorageKey(item.StorageKey).
		SetStatus(string(item.Status)).
		SetContentType(item.ContentType).
		SetSizeBytes(item.SizeBytes).
		SetChecksumSha256(item.ChecksumSHA256).
		Save(ctx)
	if err != nil {
		return domain.Document{}, err
	}
	return fromEnt(created), nil
}

func (repository *Repository) Get(ctx context.Context, id int) (domain.Document, error) {
	item, err := repository.client.DriverDocument.Get(ctx, id)
	if ent.IsNotFound(err) {
		return domain.Document{}, domain.ErrDocumentNotFound
	}
	if err != nil {
		return domain.Document{}, err
	}
	return fromEnt(item), nil
}

func (repository *Repository) ListByDriver(ctx context.Context, driverID, limit int) ([]domain.Document, error) {
	items, err := repository.client.DriverDocument.Query().
		Where(driverdocument.DriverIDEQ(driverID)).
		Order(driverdocument.ByCreatedAt(entsql.OrderDesc()), driverdocument.ByID(entsql.OrderDesc())).
		Limit(limit).
		All(ctx)
	if err != nil {
		return nil, err
	}
	return fromEntDocuments(items), nil
}

func (repository *Repository) ListForReview(ctx context.Context, status domain.Status, limit, offset int) ([]domain.Document, error) {
	items, err := repository.client.DriverDocument.Query().
		Where(driverdocument.StatusEQ(string(status))).
		Order(driverdocument.ByCreatedAt(entsql.OrderAsc()), driverdocument.ByID(entsql.OrderAsc())).
		Limit(limit + 1).
		Offset(offset).
		All(ctx)
	if err != nil {
		return nil, err
	}
	return fromEntDocuments(items), nil
}

func (repository *Repository) Review(ctx context.Context, id, reviewerID int, status domain.Status) (domain.Document, error) {
	updated, err := repository.client.DriverDocument.Update().
		Where(driverdocument.IDEQ(id), driverdocument.StatusEQ(string(domain.Pending))).
		SetStatus(string(status)).
		SetReviewedAt(time.Now()).
		SetReviewedBy(reviewerID).
		Save(ctx)
	if err != nil {
		return domain.Document{}, err
	}
	if updated == 0 {
		exists, err := repository.client.DriverDocument.Query().Where(driverdocument.IDEQ(id)).Exist(ctx)
		if err != nil {
			return domain.Document{}, err
		}
		if !exists {
			return domain.Document{}, domain.ErrDocumentNotFound
		}
		return domain.Document{}, domain.ErrDocumentFinalized
	}
	return repository.Get(ctx, id)
}

func fromEntDocuments(items []*ent.DriverDocument) []domain.Document {
	result := make([]domain.Document, 0, len(items))
	for _, item := range items {
		result = append(result, fromEnt(item))
	}
	return result
}

func fromEnt(item *ent.DriverDocument) domain.Document {
	return domain.Document{
		ID:             item.ID,
		DriverID:       item.DriverID,
		Type:           domain.Type(item.DocumentType),
		StorageKey:     item.StorageKey,
		Status:         domain.Status(item.Status),
		ContentType:    item.ContentType,
		SizeBytes:      item.SizeBytes,
		ChecksumSHA256: item.ChecksumSha256,
		CreatedAt:      item.CreatedAt,
		ReviewedAt:     item.ReviewedAt,
		ReviewedBy:     item.ReviewedBy,
	}
}
