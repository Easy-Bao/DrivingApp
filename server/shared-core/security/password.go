package security

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"strings"

	"golang.org/x/crypto/bcrypt"
)

var ErrPasswordTooLong = errors.New("password exceeds bcrypt's 72-byte limit")

const bcryptCost = 12

func HashPassword(password string) (string, error) {
	if len([]byte(password)) > 72 {
		return "", ErrPasswordTooLong
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}

func VerifyPassword(storedHash, password string) bool {
	if strings.HasPrefix(storedHash, "$2a$") ||
		strings.HasPrefix(storedHash, "$2b$") ||
		strings.HasPrefix(storedHash, "$2y$") {
		return bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(password)) == nil
	}
	legacyHash := legacyPasswordHash(password)
	return subtle.ConstantTimeCompare([]byte(storedHash), []byte(legacyHash)) == 1
}

func IsLegacyPasswordHash(storedHash string) bool {
	if len(storedHash) != sha256.Size*2 {
		return false
	}
	_, err := hex.DecodeString(storedHash)
	return err == nil
}

func legacyPasswordHash(password string) string {
	digest := sha256.Sum256([]byte(password))
	return hex.EncodeToString(digest[:])
}
