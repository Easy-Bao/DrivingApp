package usecase

import (
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

func HashPassword(password string) string {
	hash, _ := security.HashPassword(password)
	return hash
}

func HashPasswordWithError(password string) (string, error) {
	return security.HashPassword(password)
}

func VerifyPassword(storedHash, password string) bool {
	return security.VerifyPassword(storedHash, password)
}

func IsLegacyPasswordHash(storedHash string) bool {
	return security.IsLegacyPasswordHash(storedHash)
}

func intSubject(id int) string { return strconv.Itoa(id) }
