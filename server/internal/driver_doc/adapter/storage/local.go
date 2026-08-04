package storage

import (
	"context"
	"fmt"
)

// LocalStorage is an explicit development adapter. Production can replace it
// with the object-storage port without changing document use cases.
type LocalStorage struct{}

func (LocalStorage) Put(_ context.Context, driverID int, documentType string, _ []byte) (string, error) {
	return fmt.Sprintf("driver/%d/%s", driverID, documentType), nil
}
