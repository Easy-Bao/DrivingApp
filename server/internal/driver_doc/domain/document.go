package domain

type Status string

const (
	Pending  Status = "pending"
	Approved Status = "approved"
	Rejected Status = "rejected"
)

type Document struct {
	ID         int    `json:"id"`
	DriverID   int    `json:"driver_id"`
	Type       string `json:"document_type"`
	StorageKey string `json:"-"`
	Status     Status `json:"status"`
}
