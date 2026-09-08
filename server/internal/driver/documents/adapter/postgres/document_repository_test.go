package postgres

import (
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestNewDocumentRepositoryRejectsNilPool(t *testing.T) {
	if _, err := NewDocumentRepository(nil); err == nil {
		t.Fatal("expected nil PostgreSQL pool to be rejected")
	}
}

func TestFromPostgresDocumentMapsReviewMetadata(t *testing.T) {
	createdAt := time.Date(2026, time.September, 7, 13, 0, 0, 0, time.UTC)
	reviewedAt := createdAt.Add(time.Hour)
	document, err := fromPostgresDocument(databasepostgres.DriverDocument{
		ID:             3,
		DriverID:       7,
		DocumentType:   "driver_license",
		StorageKey:     "db/v1/document",
		Status:         "approved",
		ContentType:    "application/pdf",
		SizeBytes:      128,
		ChecksumSha256: "checksum",
		CreatedAt:      pgtype.Timestamptz{Time: createdAt, Valid: true},
		ReviewedAt:     pgtype.Timestamptz{Time: reviewedAt, Valid: true},
		ReviewedBy:     pgtype.Int4{Int32: 9, Valid: true},
	})
	if err != nil {
		t.Fatalf("fromPostgresDocument() error = %v", err)
	}
	if document.ID != 3 || document.DriverID != 7 || document.Status != "approved" {
		t.Fatalf("document identity = %+v", document)
	}
	if document.ReviewedAt == nil || !document.ReviewedAt.Equal(reviewedAt) {
		t.Fatalf("reviewed at = %v", document.ReviewedAt)
	}
	if document.ReviewedBy == nil || *document.ReviewedBy != 9 {
		t.Fatalf("reviewed by = %v", document.ReviewedBy)
	}
}

func TestPostgresDocumentPageValueRejectsNegativeValues(t *testing.T) {
	if _, err := toPostgresDocumentPageValue(-1, "offset"); err == nil {
		t.Fatal("expected negative page value to be rejected")
	}
}

func TestFromPostgresDocumentRejectsNullCreationTime(t *testing.T) {
	_, err := fromPostgresDocument(databasepostgres.DriverDocument{})
	if err == nil {
		t.Fatal("expected null creation time to be rejected")
	}
}
