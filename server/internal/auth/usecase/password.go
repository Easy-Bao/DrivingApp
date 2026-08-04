package usecase

import (
	"crypto/sha256"
	"encoding/hex"
	"strconv"
)

func HashPassword(password string) string {
	digest := sha256.Sum256([]byte(password))
	return hex.EncodeToString(digest[:])
}
func intSubject(id int) string { return strconv.Itoa(id) }
