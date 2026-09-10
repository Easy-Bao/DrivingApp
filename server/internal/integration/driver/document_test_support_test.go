//go:build integration

package driver_test

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
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
