package application_test

import (
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

func testPasswordHash(t *testing.T, password string) string {
	t.Helper()
	hash, err := security.HashPassword(password)
	if err != nil {
		t.Fatalf("hash test password: %v", err)
	}
	return hash
}
