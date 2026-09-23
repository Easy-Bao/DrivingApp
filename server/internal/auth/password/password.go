package password

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

func Hash(password string) (string, error) {
	return security.HashPassword(password)
}

func Verify(storedHash, password string) bool {
	return security.VerifyPassword(storedHash, password)
}

func IsLegacyHash(storedHash string) bool {
	return security.IsLegacyPasswordHash(storedHash)
}
