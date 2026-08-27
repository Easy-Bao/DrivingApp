package driver_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/usecase"
)

var validPDF = []byte("%PDF-1.7\nprivate driver document")

type documentRepositoryFake struct {
	documents map[int]domain.Document
	createErr error
}

func newDocumentRepositoryFake() *documentRepositoryFake {
	return &documentRepositoryFake{documents: make(map[int]domain.Document)}
}

func (repository *documentRepositoryFake) Create(_ context.Context, document domain.Document) (domain.Document, error) {
	if repository.createErr != nil {
		return domain.Document{}, repository.createErr
	}
	document.ID = len(repository.documents) + 1
	document.CreatedAt = time.Now().UTC()
	repository.documents[document.ID] = document
	return document, nil
}

func (repository *documentRepositoryFake) Get(_ context.Context, id int) (domain.Document, error) {
	document, ok := repository.documents[id]
	if !ok {
		return domain.Document{}, domain.ErrDocumentNotFound
	}
	return document, nil
}

func (repository *documentRepositoryFake) ListByDriver(_ context.Context, driverID, limit int) ([]domain.Document, error) {
	items := make([]domain.Document, 0, limit)
	for _, document := range repository.documents {
		if document.DriverID == driverID && len(items) < limit {
			items = append(items, document)
		}
	}
	return items, nil
}

func (repository *documentRepositoryFake) ListForReview(_ context.Context, status domain.Status, limit, offset int) ([]domain.Document, error) {
	items := make([]domain.Document, 0, limit+1)
	for _, document := range repository.documents {
		if document.Status == status {
			items = append(items, document)
		}
	}
	if offset >= len(items) {
		return nil, nil
	}
	items = items[offset:]
	if len(items) > limit+1 {
		items = items[:limit+1]
	}
	return items, nil
}

func (repository *documentRepositoryFake) Review(_ context.Context, id, reviewerID int, status domain.Status) (domain.Document, error) {
	document, ok := repository.documents[id]
	if !ok {
		return domain.Document{}, domain.ErrDocumentNotFound
	}
	if document.Status != domain.Pending {
		return domain.Document{}, domain.ErrDocumentFinalized
	}
	now := time.Now().UTC()
	document.Status = status
	document.ReviewedAt = &now
	document.ReviewedBy = &reviewerID
	repository.documents[id] = document
	return document, nil
}

type documentStorageFake struct {
	objects map[string][]byte
	deleted []string
}

func newDocumentStorageFake() *documentStorageFake {
	return &documentStorageFake{objects: make(map[string][]byte)}
}

func (storage *documentStorageFake) Store(_ context.Context, content []byte) (string, error) {
	key := fmt.Sprintf("v1/object-%d", len(storage.objects)+1)
	storage.objects[key] = append([]byte(nil), content...)
	return key, nil
}

func (storage *documentStorageFake) Read(_ context.Context, key string, maxBytes int64) ([]byte, error) {
	content, ok := storage.objects[key]
	if !ok {
		return nil, errors.New("object not found")
	}
	if int64(len(content)) > maxBytes {
		return nil, errors.New("object too large")
	}
	return append([]byte(nil), content...), nil
}

func (storage *documentStorageFake) Delete(_ context.Context, key string) error {
	delete(storage.objects, key)
	storage.deleted = append(storage.deleted, key)
	return nil
}

func TestUploadCreatesAnImmutablePendingRevision(t *testing.T) {
	repository := newDocumentRepositoryFake()
	storage := newDocumentStorageFake()
	service := usecase.NewDocumentService(repository, storage, 1024)

	document, err := service.Upload(context.Background(), 3, "driver_license", "application/pdf", validPDF)
	if err != nil {
		t.Fatal(err)
	}
	if document.Status != domain.Pending || document.Type != domain.DriverLicense {
		t.Fatalf("document = %#v", document)
	}
	if document.SizeBytes != int64(len(validPDF)) || len(document.ChecksumSHA256) != 64 {
		t.Fatalf("integrity metadata = %#v", document)
	}
	if got := storage.objects[document.StorageKey]; string(got) != string(validPDF) {
		t.Fatalf("stored content = %q", got)
	}
	encoded, err := json.Marshal(document)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(encoded), document.StorageKey) || strings.Contains(string(encoded), document.ChecksumSHA256) {
		t.Fatalf("private object metadata leaked in %s", encoded)
	}
}

func TestUploadRejectsMismatchedContentBeforeStorage(t *testing.T) {
	storage := newDocumentStorageFake()
	service := usecase.NewDocumentService(newDocumentRepositoryFake(), storage, 1024)

	_, err := service.Upload(context.Background(), 3, "driver_license", "image/png", validPDF)
	if !errors.Is(err, domain.ErrUnsupportedContentType) {
		t.Fatalf("error = %v", err)
	}
	if len(storage.objects) != 0 {
		t.Fatal("invalid content reached private storage")
	}
}

func TestUploadRemovesObjectWhenMetadataCreationFails(t *testing.T) {
	repository := newDocumentRepositoryFake()
	repository.createErr = errors.New("database unavailable")
	storage := newDocumentStorageFake()
	service := usecase.NewDocumentService(repository, storage, 1024)

	_, err := service.Upload(context.Background(), 3, "driver_license", "application/pdf", validPDF)
	if err == nil || len(storage.deleted) != 1 || len(storage.objects) != 0 {
		t.Fatalf("error = %v, deleted = %v, objects = %v", err, storage.deleted, storage.objects)
	}
}

func TestDocumentContentEnforcesOwnershipAndIntegrity(t *testing.T) {
	repository := newDocumentRepositoryFake()
	storage := newDocumentStorageFake()
	service := usecase.NewDocumentService(repository, storage, 1024)
	document, err := service.Upload(context.Background(), 3, "driver_license", "application/pdf", validPDF)
	if err != nil {
		t.Fatal(err)
	}

	if _, err := service.DriverContent(context.Background(), 4, document.ID); !errors.Is(err, domain.ErrDocumentNotFound) {
		t.Fatalf("cross-driver error = %v", err)
	}
	storage.objects[document.StorageKey][0] = 'X'
	if _, err := service.DriverContent(context.Background(), 3, document.ID); !errors.Is(err, domain.ErrDocumentCorrupt) {
		t.Fatalf("tampered content error = %v", err)
	}
}

func TestReviewCannotRewriteAFinalDecision(t *testing.T) {
	repository := newDocumentRepositoryFake()
	storage := newDocumentStorageFake()
	service := usecase.NewDocumentService(repository, storage, 1024)
	document, err := service.Upload(context.Background(), 3, "driver_license", "application/pdf", validPDF)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.Review(context.Background(), document.ID, 42, domain.Approved); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Review(context.Background(), document.ID, 42, domain.Rejected); !errors.Is(err, domain.ErrDocumentFinalized) {
		t.Fatalf("second review error = %v", err)
	}
}
