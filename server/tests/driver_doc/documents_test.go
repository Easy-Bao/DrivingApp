package driver_doc_test

import (
	"context"
	"testing"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/usecase"
)
type repository struct{}
func (repository) Create(_ context.Context, document domain.Document) (domain.Document, error) { document.ID = 1; return document, nil }
func (repository) List(context.Context, int) ([]domain.Document, error) { return nil, nil }
func (repository) Review(_ context.Context, id int, status domain.Status) (domain.Document, error) { return domain.Document{ID: id, Status: status}, nil }
type storage struct{}
func (storage) Put(context.Context, int, string, []byte) (string, error) { return "driver/document", nil }
func TestUploadStartsPending(t *testing.T) { document, err := usecase.NewService(repository{}, storage{}).Upload(context.Background(), 3, "license", []byte("file")); if err != nil || document.Status != domain.Pending { t.Fatalf("document = %#v, %v", document, err) } }
