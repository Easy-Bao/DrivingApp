package http

import (
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
)

type DocumentResponse struct {
	ID          int           `json:"id"`
	DriverID    int           `json:"driver_id"`
	Type        domain.Type   `json:"document_type"`
	Status      domain.Status `json:"status"`
	ContentType string        `json:"content_type"`
	SizeBytes   int64         `json:"size_bytes"`
	CreatedAt   time.Time     `json:"created_at"`
	ReviewedAt  *time.Time    `json:"reviewed_at,omitempty"`
}

func NewDocumentResponse(document domain.Document) DocumentResponse {
	return DocumentResponse{
		ID:          document.ID,
		DriverID:    document.DriverID,
		Type:        document.Type,
		Status:      document.Status,
		ContentType: document.ContentType,
		SizeBytes:   document.SizeBytes,
		CreatedAt:   document.CreatedAt,
		ReviewedAt:  document.ReviewedAt,
	}
}

func NewDocumentResponses(documents []domain.Document) []DocumentResponse {
	if documents == nil {
		return nil
	}

	responses := make([]DocumentResponse, 0, len(documents))
	for _, document := range documents {
		responses = append(responses, NewDocumentResponse(document))
	}
	return responses
}
