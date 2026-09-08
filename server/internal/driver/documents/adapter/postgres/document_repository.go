package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

const maxPostgresDocumentID = 1<<31 - 1

// PostgresDocumentRepository persists driver-document metadata through the
// generated PostgreSQL queries.
type PostgresDocumentRepository struct {
	pool    *pgxpool.Pool
	queries *databasepostgres.Queries
}

var _ domain.Repository = (*PostgresDocumentRepository)(nil)

func NewPostgresDocumentRepository(pool *pgxpool.Pool) (*PostgresDocumentRepository, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &PostgresDocumentRepository{
		pool:    pool,
		queries: databasepostgres.New(pool),
	}, nil
}

func (repository *PostgresDocumentRepository) Create(ctx context.Context, item domain.Document) (domain.Document, error) {
	if err := repository.validate(); err != nil {
		return domain.Document{}, err
	}
	driverID, err := toPostgresDocumentID(item.DriverID, "driver id")
	if err != nil {
		return domain.Document{}, err
	}
	created, err := repository.queries.CreateDriverDocument(ctx, databasepostgres.CreateDriverDocumentParams{
		DriverID:       driverID,
		DocumentType:   string(item.Type),
		StorageKey:     item.StorageKey,
		Status:         string(item.Status),
		ContentType:    item.ContentType,
		SizeBytes:      item.SizeBytes,
		ChecksumSha256: item.ChecksumSHA256,
	})
	if err != nil {
		return domain.Document{}, fmt.Errorf("create driver document: %w", err)
	}
	return fromPostgresDocument(created)
}

func (repository *PostgresDocumentRepository) Get(ctx context.Context, id int) (domain.Document, error) {
	if err := repository.validate(); err != nil {
		return domain.Document{}, err
	}
	documentID, err := toPostgresDocumentID(id, "document id")
	if err != nil {
		return domain.Document{}, err
	}
	item, err := repository.queries.GetDriverDocumentByID(ctx, documentID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Document{}, domain.ErrDocumentNotFound
	}
	if err != nil {
		return domain.Document{}, fmt.Errorf("find driver document: %w", err)
	}
	return fromPostgresDocument(item)
}

func (repository *PostgresDocumentRepository) ListByDriver(ctx context.Context, driverID, limit int) ([]domain.Document, error) {
	if err := repository.validate(); err != nil {
		return nil, err
	}
	dbDriverID, err := toPostgresDocumentID(driverID, "driver id")
	if err != nil {
		return nil, err
	}
	dbLimit, err := toPostgresDocumentPageValue(limit, "limit")
	if err != nil {
		return nil, err
	}
	items, err := repository.queries.ListDriverDocumentsByDriverID(ctx, databasepostgres.ListDriverDocumentsByDriverIDParams{
		DriverID: dbDriverID,
		Limit:    dbLimit,
	})
	if err != nil {
		return nil, fmt.Errorf("list driver documents: %w", err)
	}
	return fromPostgresDocuments(items)
}

func (repository *PostgresDocumentRepository) ListForReview(ctx context.Context, status domain.Status, limit, offset int) ([]domain.Document, error) {
	if err := repository.validate(); err != nil {
		return nil, err
	}
	if limit == int(^uint(0)>>1) {
		return nil, errors.New("limit exceeds PostgreSQL integer range")
	}
	dbLimit, err := toPostgresDocumentPageValue(limit+1, "limit")
	if err != nil {
		return nil, err
	}
	dbOffset, err := toPostgresDocumentPageValue(offset, "offset")
	if err != nil {
		return nil, err
	}
	items, err := repository.queries.ListDriverDocumentsForReview(ctx, databasepostgres.ListDriverDocumentsForReviewParams{
		Status: string(status),
		Limit:  dbLimit,
		Offset: dbOffset,
	})
	if err != nil {
		return nil, fmt.Errorf("list driver documents for review: %w", err)
	}
	return fromPostgresDocuments(items)
}

func (repository *PostgresDocumentRepository) Review(ctx context.Context, id, reviewerID int, status domain.Status) (domain.Document, error) {
	if err := repository.validate(); err != nil {
		return domain.Document{}, err
	}
	documentID, err := toPostgresDocumentID(id, "document id")
	if err != nil {
		return domain.Document{}, err
	}
	dbReviewerID, err := toPostgresDocumentID(reviewerID, "reviewer id")
	if err != nil {
		return domain.Document{}, err
	}
	updated, err := repository.queries.ReviewDriverDocument(ctx, databasepostgres.ReviewDriverDocumentParams{
		ID:         documentID,
		Status:     string(status),
		ReviewedAt: toPostgresDocumentTimestamp(time.Now()),
		ReviewedBy: pgtype.Int4{Int32: dbReviewerID, Valid: true},
	})
	if errors.Is(err, pgx.ErrNoRows) {
		return repository.reviewMiss(ctx, documentID)
	}
	if err != nil {
		return domain.Document{}, fmt.Errorf("review driver document: %w", err)
	}
	return fromPostgresDocument(updated)
}

func (repository *PostgresDocumentRepository) reviewMiss(ctx context.Context, documentID int32) (domain.Document, error) {
	_, err := repository.queries.GetDriverDocumentByID(ctx, documentID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Document{}, domain.ErrDocumentNotFound
	}
	if err != nil {
		return domain.Document{}, fmt.Errorf("check driver document review state: %w", err)
	}
	return domain.Document{}, domain.ErrDocumentFinalized
}

func (repository *PostgresDocumentRepository) validate() error {
	if repository == nil || repository.pool == nil || repository.queries == nil {
		return errors.New("postgresql document repository is not initialized")
	}
	return nil
}

func fromPostgresDocuments(items []databasepostgres.DriverDocument) ([]domain.Document, error) {
	result := make([]domain.Document, 0, len(items))
	for _, item := range items {
		document, err := fromPostgresDocument(item)
		if err != nil {
			return nil, err
		}
		result = append(result, document)
	}
	return result, nil
}

func fromPostgresDocument(item databasepostgres.DriverDocument) (domain.Document, error) {
	if !item.CreatedAt.Valid {
		return domain.Document{}, errors.New("driver document creation time is null")
	}
	document := domain.Document{
		ID:             int(item.ID),
		DriverID:       int(item.DriverID),
		Type:           domain.Type(item.DocumentType),
		StorageKey:     item.StorageKey,
		Status:         domain.Status(item.Status),
		ContentType:    item.ContentType,
		SizeBytes:      item.SizeBytes,
		ChecksumSHA256: item.ChecksumSha256,
		CreatedAt:      item.CreatedAt.Time,
	}
	if item.ReviewedAt.Valid {
		reviewedAt := item.ReviewedAt.Time
		document.ReviewedAt = &reviewedAt
	}
	if item.ReviewedBy.Valid {
		reviewedBy := int(item.ReviewedBy.Int32)
		document.ReviewedBy = &reviewedBy
	}
	return document, nil
}

func toPostgresDocumentPageValue(value int, field string) (int32, error) {
	if value < 0 || int64(value) > int64(maxPostgresDocumentID) {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

func toPostgresDocumentID(value int, field string) (int32, error) {
	if value <= 0 || int64(value) > int64(maxPostgresDocumentID) {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

func toPostgresDocumentTimestamp(value time.Time) pgtype.Timestamptz {
	return pgtype.Timestamptz{Time: value, Valid: true}
}
