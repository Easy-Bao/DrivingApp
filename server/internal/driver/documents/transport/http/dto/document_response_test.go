package dto

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
)

func TestDocumentResponsePreservesPublicFieldsAndHidesStorageMetadata(t *testing.T) {
	createdAt := time.Date(2026, time.October, 12, 1, 2, 3, 0, time.UTC)
	reviewedAt := createdAt.Add(time.Hour)
	reviewedBy := 17
	document := domain.Document{
		ID:             3,
		DriverID:       7,
		Type:           domain.DriverLicense,
		StorageKey:     "private/object-key",
		Status:         domain.Approved,
		ContentType:    "application/pdf",
		SizeBytes:      128,
		ChecksumSHA256: "private-checksum",
		CreatedAt:      createdAt,
		ReviewedAt:     &reviewedAt,
		ReviewedBy:     &reviewedBy,
	}

	encoded, err := json.Marshal(NewDocumentResponse(document))
	if err != nil {
		t.Fatalf("marshal document response: %v", err)
	}
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(encoded, &fields); err != nil {
		t.Fatalf("decode document response: %v", err)
	}
	for field, expected := range map[string]string{
		"id":            "3",
		"driver_id":     "7",
		"document_type": `"driver_license"`,
		"status":        `"approved"`,
		"content_type":  `"application/pdf"`,
		"size_bytes":    "128",
		"created_at":    `"2026-10-12T01:02:03Z"`,
		"reviewed_at":   `"2026-10-12T02:02:03Z"`,
	} {
		if string(fields[field]) != expected {
			t.Errorf("field %q = %s, want %s", field, fields[field], expected)
		}
	}
	for _, field := range []string{"storage_key", "checksum_sha256", "reviewed_by"} {
		if _, exists := fields[field]; exists {
			t.Errorf("response included private or omitted field %q", field)
		}
	}
	for _, secret := range []string{document.StorageKey, document.ChecksumSHA256} {
		if strings.Contains(string(encoded), secret) {
			t.Errorf("response exposed private metadata %q", secret)
		}
	}
}

func TestNewDocumentResponsesPreservesNilSlice(t *testing.T) {
	if responses := NewDocumentResponses(nil); responses != nil {
		t.Fatalf("NewDocumentResponses(nil) = %#v, want nil", responses)
	}
}
