package token

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"strings"
	"time"
)

var (
	ErrInvalidToken = errors.New("invalid token")
	ErrMissingToken = errors.New("missing token")
)

type Verifier struct {
	secret []byte
}

func NewVerifier(secret string) *Verifier {
	return &Verifier{secret: []byte(secret)}
}

type claims struct {
	Subject   string `json:"sub"`
	ExpiresAt int64  `json:"exp"`
}

func (verifier *Verifier) Verify(raw string) (string, error) {
	if raw == "" {
		return "", ErrMissingToken
	}
	parts := strings.Split(raw, ".")
	if len(parts) != 3 || len(verifier.secret) == 0 {
		return "", ErrInvalidToken
	}

	mac := hmac.New(sha256.New, verifier.secret)
	_, _ = mac.Write([]byte(parts[0] + "." + parts[1]))
	signature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil || !hmac.Equal(signature, mac.Sum(nil)) {
		return "", ErrInvalidToken
	}

	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return "", ErrInvalidToken
	}
	var parsed claims
	if json.Unmarshal(payload, &parsed) != nil || parsed.Subject == "" ||
		parsed.ExpiresAt == 0 || time.Now().Unix() >= parsed.ExpiresAt {
		return "", ErrInvalidToken
	}
	return parsed.Subject, nil
}
