package security

import (
	"crypto/sha256"
	"encoding/hex"
)

func HashPassword(password string) string {
	digest := sha256.Sum256([]byte(password))
	return hex.EncodeToString(digest[:])
}
