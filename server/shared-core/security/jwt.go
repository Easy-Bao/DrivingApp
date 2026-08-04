package security

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrInvalidToken = errors.New("invalid token")
	ErrMissingToken = errors.New("missing token")
)

type TokenManager struct {
	secret   []byte
	lifetime time.Duration
}

func NewTokenManager(secret string) *TokenManager {
	return &TokenManager{secret: []byte(secret), lifetime: 24 * time.Hour}
}

func (manager *TokenManager) Issue(subject string) (string, error) {
	if len(manager.secret) == 0 {
		return "", fmt.Errorf("token secret is required")
	}
	header := encode([]byte(`{"alg":"HS256","typ":"JWT"}`))
	payload := encode([]byte(fmt.Sprintf(`{"sub":%q,"exp":%d}`, subject, time.Now().Add(manager.lifetime).Unix())))
	signature := manager.sign(header + "." + payload)
	return header + "." + payload + "." + base64.RawURLEncoding.EncodeToString(signature), nil
}

func (manager *TokenManager) Verify(rawToken string) (string, error) {
	if rawToken == "" {
		return "", ErrMissingToken
	}
	parts := strings.Split(rawToken, ".")
	if len(parts) != 3 || len(manager.secret) == 0 {
		return "", ErrInvalidToken
	}
	signature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil || !hmac.Equal(signature, manager.sign(parts[0]+"."+parts[1])) {
		return "", ErrInvalidToken
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return "", ErrInvalidToken
	}
	var claims struct {
		Subject string `json:"sub"`
		Expires int64  `json:"exp"`
	}
	if json.Unmarshal(payload, &claims) != nil || claims.Subject == "" || claims.Expires <= time.Now().Unix() {
		return "", ErrInvalidToken
	}
	return claims.Subject, nil
}

func (manager *TokenManager) sign(message string) []byte {
	hasher := hmac.New(sha256.New, manager.secret)
	_, _ = hasher.Write([]byte(message))
	return hasher.Sum(nil)
}

func encode(value []byte) string { return base64.RawURLEncoding.EncodeToString(value) }
