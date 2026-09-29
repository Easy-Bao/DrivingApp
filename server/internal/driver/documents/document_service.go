package documents

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"mime"
	"slices"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
)

type DocumentService struct {
	repository        DocumentStore
	storage           ObjectStore
	detectContentType ContentTypeDetector
	maxDocumentBytes  int64
}

var ErrServiceUnavailable = errors.New("driver document service is unavailable")

const _defaultMaxDocumentBytes int64 = 10 << 20

type DocumentServiceOption func(*DocumentService)

type ContentTypeDetector func([]byte) string

func WithContentTypeDetector(detector ContentTypeDetector) DocumentServiceOption {
	return func(service *DocumentService) {
		if detector != nil {
			service.detectContentType = detector
		}
	}
}

func WithMaxDocumentBytes(limit int64) DocumentServiceOption {
	return func(service *DocumentService) {
		if limit > 0 {
			service.maxDocumentBytes = limit
		}
	}
}

func NewDocumentService(
	repository DocumentStore,
	storage ObjectStore,
	options ...DocumentServiceOption,
) *DocumentService {
	service := &DocumentService{
		repository:       repository,
		storage:          storage,
		maxDocumentBytes: _defaultMaxDocumentBytes,
	}
	for _, option := range options {
		if option != nil {
			option(service)
		}
	}
	return service
}

func (service *DocumentService) MaxDocumentBytes() int64 {
	return service.maxDocumentBytes
}

func (service *DocumentService) Upload(
	ctx context.Context,
	driverID int,
	rawType string,
	claimedContentType string,
	content []byte,
) (domain.Document, error) {
	invalidDriverID := driverID <= 0
	invalidSize := len(content) == 0 || int64(len(content)) > service.maxDocumentBytes
	if invalidDriverID || invalidSize {
		return domain.Document{}, domain.ErrInvalidDocument
	}
	if service.repository == nil || service.storage == nil {
		return domain.Document{}, ErrServiceUnavailable
	}
	if service.detectContentType == nil {
		return domain.Document{}, ErrServiceUnavailable
	}
	documentType, err := domain.ParseType(rawType)
	if err != nil {
		return domain.Document{}, err
	}
	contentType, err := verifiedContentType(claimedContentType, content, service.detectContentType)
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
	persistenceErr := fmt.Errorf("persist driver document metadata: %w", err)
	if cleanupErr := service.storage.Delete(context.WithoutCancel(ctx), key); cleanupErr != nil {
		return domain.Document{}, errors.Join(
			persistenceErr,
			fmt.Errorf("remove orphaned driver document: %w", cleanupErr),
		)
	}
	return domain.Document{}, persistenceErr
}

func (service *DocumentService) Status(ctx context.Context, driverID int) ([]domain.Document, error) {
	if driverID <= 0 {
		return nil, domain.ErrInvalidDocument
	}
	if service.repository == nil {
		return nil, ErrServiceUnavailable
	}
	documents, err := service.repository.ListByDriver(ctx, driverID, 20)
	if err != nil {
		return nil, fmt.Errorf("load driver document status: %w", err)
	}
	return slices.Clone(documents), nil
}

func (service *DocumentService) ReviewQueue(
	ctx context.Context,
	status domain.Status,
	limit int,
	offset int,
) ([]domain.Document, error) {
	validStatus := status == domain.Pending || status == domain.Approved || status == domain.Rejected
	if !validStatus {
		return nil, domain.ErrInvalidDocument
	}
	invalidLimit := limit <= 0 || limit > 100
	invalidOffset := offset < 0
	if invalidLimit || invalidOffset {
		return nil, domain.ErrInvalidDocument
	}
	if service.repository == nil {
		return nil, ErrServiceUnavailable
	}
	documents, err := service.repository.ListForReview(
		ctx,
		status,
		limit,
		offset,
	)
	if err != nil {
		return nil, fmt.Errorf("load driver document review queue: %w", err)
	}
	return slices.Clone(documents), nil
}

func (service *DocumentService) Review(
	ctx context.Context,
	id int,
	reviewerID int,
	status domain.Status,
) (domain.Document, error) {
	invalidIdentity := id <= 0 || reviewerID <= 0
	invalidStatus := status != domain.Approved && status != domain.Rejected
	if invalidIdentity || invalidStatus {
		return domain.Document{}, domain.ErrInvalidDocument
	}
	if service.repository == nil {
		return domain.Document{}, ErrServiceUnavailable
	}
	document, err := service.repository.Review(
		ctx,
		id,
		reviewerID,
		status,
	)
	if err != nil {
		return domain.Document{}, fmt.Errorf("review driver document: %w", err)
	}
	return document, nil
}

func (service *DocumentService) DriverContent(ctx context.Context, driverID, documentID int) (domain.Content, error) {
	if service.repository == nil || service.storage == nil {
		return domain.Content{}, ErrServiceUnavailable
	}
	document, err := service.repository.Get(ctx, documentID)
	if err != nil {
		return domain.Content{}, fmt.Errorf("load driver document: %w", err)
	}
	if driverID <= 0 || document.DriverID != driverID {
		return domain.Content{}, domain.ErrDocumentNotFound
	}
	return service.readContent(ctx, document)
}

func (service *DocumentService) AdminContent(ctx context.Context, documentID int) (domain.Content, error) {
	if service.repository == nil || service.storage == nil {
		return domain.Content{}, ErrServiceUnavailable
	}
	document, err := service.repository.Get(ctx, documentID)
	if err != nil {
		return domain.Content{}, fmt.Errorf("load driver document: %w", err)
	}
	return service.readContent(ctx, document)
}

func (service *DocumentService) readContent(ctx context.Context, document domain.Document) (domain.Content, error) {
	if service.detectContentType == nil {
		return domain.Content{}, ErrServiceUnavailable
	}
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
	detectedType, err := verifiedContentType(document.ContentType, content, service.detectContentType)
	if err != nil {
		if document.ContentType != "" && document.ContentType != "application/octet-stream" {
			return domain.Content{}, domain.ErrDocumentCorrupt
		}
		detectedType, err = verifiedContentType(
			service.detectContentType(content),
			content,
			service.detectContentType,
		)
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

func verifiedContentType(
	claimed string,
	content []byte,
	detectContentType ContentTypeDetector,
) (string, error) {
	claimedType, _, err := mime.ParseMediaType(strings.TrimSpace(claimed))
	if err != nil {
		return "", domain.ErrUnsupportedContentType
	}
	detectedType := detectContentType(content)
	if !isAllowedContentType(detectedType) || claimedType != detectedType {
		return "", domain.ErrUnsupportedContentType
	}
	return detectedType, nil
}

func isAllowedContentType(contentType string) bool {
	switch contentType {
	case "application/pdf", "image/jpeg", "image/png":
		return true
	default:
		return false
	}
}
