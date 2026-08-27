package usecase

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"mime"
	"net/http"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
)

const defaultMaxDocumentBytes int64 = 10 << 20

var allowedContentTypes = map[string]struct{}{
	"application/pdf": {},
	"image/jpeg":      {},
	"image/png":       {},
}

type DocumentService struct {
	repository       domain.Repository
	storage          domain.ObjectStorage
	maxDocumentBytes int64
}

func NewDocumentService(repository domain.Repository, storage domain.ObjectStorage, maxDocumentBytes ...int64) *DocumentService {
	limit := defaultMaxDocumentBytes
	if len(maxDocumentBytes) > 0 && maxDocumentBytes[0] > 0 {
		limit = maxDocumentBytes[0]
	}
	return &DocumentService{repository: repository, storage: storage, maxDocumentBytes: limit}
}

func (service *DocumentService) MaxDocumentBytes() int64 {
	return service.maxDocumentBytes
}

func (service *DocumentService) Upload(ctx context.Context, driverID int, rawType, claimedContentType string, content []byte) (domain.Document, error) {
	if driverID <= 0 || len(content) == 0 || int64(len(content)) > service.maxDocumentBytes {
		return domain.Document{}, domain.ErrInvalidDocument
	}
	documentType, err := domain.ParseType(rawType)
	if err != nil {
		return domain.Document{}, err
	}
	contentType, err := verifiedContentType(claimedContentType, content)
	if err != nil {
		return domain.Document{}, err
	}
	checksum := sha256.Sum256(content)
	key, err := service.storage.Store(ctx, content)
	if err != nil {
		return domain.Document{}, fmt.Errorf("store private driver document: %w", err)
	}
	document, err := service.repository.Create(ctx, domain.Document{
		DriverID:       driverID,
		Type:           documentType,
		StorageKey:     key,
		Status:         domain.Pending,
		ContentType:    contentType,
		SizeBytes:      int64(len(content)),
		ChecksumSHA256: hex.EncodeToString(checksum[:]),
	})
	if err == nil {
		return document, nil
	}
	if cleanupErr := service.storage.Delete(context.WithoutCancel(ctx), key); cleanupErr != nil {
		return domain.Document{}, errors.Join(err, fmt.Errorf("remove orphaned driver document: %w", cleanupErr))
	}
	return domain.Document{}, err
}

func (service *DocumentService) Status(ctx context.Context, driverID int) ([]domain.Document, error) {
	if driverID <= 0 {
		return nil, domain.ErrInvalidDocument
	}
	return service.repository.ListByDriver(ctx, driverID, 20)
}

func (service *DocumentService) ReviewQueue(ctx context.Context, status domain.Status, limit, offset int) ([]domain.Document, error) {
	if status != domain.Pending && status != domain.Approved && status != domain.Rejected {
		return nil, domain.ErrInvalidDocument
	}
	if limit <= 0 || limit > 100 || offset < 0 {
		return nil, domain.ErrInvalidDocument
	}
	return service.repository.ListForReview(ctx, status, limit, offset)
}

func (service *DocumentService) Review(ctx context.Context, id, reviewerID int, status domain.Status) (domain.Document, error) {
	if id <= 0 || reviewerID <= 0 || (status != domain.Approved && status != domain.Rejected) {
		return domain.Document{}, domain.ErrInvalidDocument
	}
	return service.repository.Review(ctx, id, reviewerID, status)
}

func (service *DocumentService) DriverContent(ctx context.Context, driverID, documentID int) (domain.Content, error) {
	document, err := service.repository.Get(ctx, documentID)
	if err != nil {
		return domain.Content{}, err
	}
	if driverID <= 0 || document.DriverID != driverID {
		return domain.Content{}, domain.ErrDocumentNotFound
	}
	return service.readContent(ctx, document)
}

func (service *DocumentService) AdminContent(ctx context.Context, documentID int) (domain.Content, error) {
	document, err := service.repository.Get(ctx, documentID)
	if err != nil {
		return domain.Content{}, err
	}
	return service.readContent(ctx, document)
}

func (service *DocumentService) readContent(ctx context.Context, document domain.Document) (domain.Content, error) {
	content, err := service.storage.Read(ctx, document.StorageKey, service.maxDocumentBytes)
	if err != nil {
		return domain.Content{}, errors.Join(
			domain.ErrDocumentCorrupt,
			fmt.Errorf("read private driver document: %w", err),
		)
	}
	if len(content) == 0 || int64(len(content)) > service.maxDocumentBytes {
		return domain.Content{}, domain.ErrDocumentCorrupt
	}
	detectedType, err := verifiedContentType(document.ContentType, content)
	if err != nil {
		if document.ContentType != "" && document.ContentType != "application/octet-stream" {
			return domain.Content{}, domain.ErrDocumentCorrupt
		}
		detectedType, err = verifiedContentType(http.DetectContentType(content), content)
		if err != nil {
			return domain.Content{}, domain.ErrDocumentCorrupt
		}
	}
	if document.SizeBytes > 0 && document.SizeBytes != int64(len(content)) {
		return domain.Content{}, domain.ErrDocumentCorrupt
	}
	if document.ChecksumSHA256 != "" {
		checksum := sha256.Sum256(content)
		if !strings.EqualFold(document.ChecksumSHA256, hex.EncodeToString(checksum[:])) {
			return domain.Content{}, domain.ErrDocumentCorrupt
		}
	}
	document.ContentType = detectedType
	document.SizeBytes = int64(len(content))
	return domain.Content{Document: document, Bytes: content}, nil
}

func verifiedContentType(claimed string, content []byte) (string, error) {
	claimedType, _, err := mime.ParseMediaType(strings.TrimSpace(claimed))
	if err != nil {
		return "", domain.ErrUnsupportedContentType
	}
	detectedType := http.DetectContentType(content)
	if _, allowed := allowedContentTypes[detectedType]; !allowed || claimedType != detectedType {
		return "", domain.ErrUnsupportedContentType
	}
	return detectedType, nil
}
