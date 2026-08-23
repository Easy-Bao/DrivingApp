package domain

import (
	"errors"
	"strings"
	"time"
)

type Status string

const (
	Pending  Status = "pending"
	Approved Status = "approved"
	Rejected Status = "rejected"
)

type Type string

const (
	DriverLicense       Type = "driver_license"
	VehicleRegistration Type = "vehicle_registration"
	VehicleInsurance    Type = "vehicle_insurance"
	GovernmentID        Type = "government_id"
)

var (
	ErrInvalidDocumentType    = errors.New("invalid driver document type")
	ErrInvalidDocument        = errors.New("invalid driver document")
	ErrUnsupportedContentType = errors.New("unsupported driver document content type")
	ErrDocumentNotFound       = errors.New("driver document not found")
	ErrDocumentFinalized      = errors.New("driver document review is finalized")
	ErrDocumentCorrupt        = errors.New("driver document content failed integrity validation")
)

func ParseType(value string) (Type, error) {
	documentType := Type(strings.TrimSpace(value))
	switch documentType {
	case DriverLicense, VehicleRegistration, VehicleInsurance, GovernmentID:
		return documentType, nil
	default:
		return "", ErrInvalidDocumentType
	}
}

func ParseReviewStatus(value string) (Status, error) {
	status := Status(strings.TrimSpace(value))
	if status != Approved && status != Rejected {
		return "", ErrInvalidDocument
	}
	return status, nil
}

type Document struct {
	ID             int        `json:"id"`
	DriverID       int        `json:"driver_id"`
	Type           Type       `json:"document_type"`
	StorageKey     string     `json:"-"`
	Status         Status     `json:"status"`
	ContentType    string     `json:"content_type"`
	SizeBytes      int64      `json:"size_bytes"`
	ChecksumSHA256 string     `json:"-"`
	CreatedAt      time.Time  `json:"created_at"`
	ReviewedAt     *time.Time `json:"reviewed_at,omitempty"`
	ReviewedBy     *int       `json:"-"`
}

type Content struct {
	Document Document
	Bytes    []byte
}
