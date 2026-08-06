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

type Identity struct {
	Subject string
	Role    string
}

const MinimumTokenSecretBytes = 32

func NewTokenManager(secret string) *TokenManager {
	return &TokenManager{secret: []byte(secret), lifetime: 24 * time.Hour}
}

func (manager *TokenManager) Issue(subject string) (string, error) {
	return manager.IssueWithRole(subject, "")
}

func (manager *TokenManager) IssueWithRole(subject, role string) (string, error) {
	if len(manager.secret) == 0 {
		return "", fmt.Errorf("token secret is required")
	}
	header := encode([]byte(`{"alg":"HS256","typ":"JWT"}`))
	claims, err := json.Marshal(struct {
		Subject string `json:"sub"`
		Role    string `json:"role,omitempty"`
		Expires int64  `json:"exp"`
	}{Subject: subject, Role: role, Expires: time.Now().Add(manager.lifetime).Unix()})
	if err != nil {
		return "", err
	}
	payload := encode(claims)
	signature := manager.sign(header + "." + payload)
	return header + "." + payload + "." + base64.RawURLEncoding.EncodeToString(signature), nil
}

func (manager *TokenManager) Verify(rawToken string) (string, error) {
	identity, err := manager.VerifyIdentity(rawToken)
	if err != nil {
		return "", err
	}
	return identity.Subject, nil
}

func (manager *TokenManager) VerifyIdentity(rawToken string) (Identity, error) {
	if rawToken == "" {
		return Identity{}, ErrMissingToken
	}
	parts := strings.Split(rawToken, ".")
	if len(parts) != 3 || len(manager.secret) == 0 {
		return Identity{}, ErrInvalidToken
	}
	signature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil || !hmac.Equal(signature, manager.sign(parts[0]+"."+parts[1])) {
		return Identity{}, ErrInvalidToken
	}
	header, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		return Identity{}, ErrInvalidToken
	}
	var headerClaims struct {
		Algorithm string `json:"alg"`
		Type      string `json:"typ"`
	}
	if json.Unmarshal(header, &headerClaims) != nil ||
		headerClaims.Algorithm != "HS256" || headerClaims.Type != "JWT" {
		return Identity{}, ErrInvalidToken
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return Identity{}, ErrInvalidToken
	}
	var claims struct {
		Subject string `json:"sub"`
		Role    string `json:"role"`
		Expires int64  `json:"exp"`
	}
	if json.Unmarshal(payload, &claims) != nil || claims.Subject == "" || claims.Expires <= time.Now().Unix() {
		return Identity{}, ErrInvalidToken
	}
	return Identity{Subject: claims.Subject, Role: claims.Role}, nil
}

func ValidateTokenSecret(secret string) error {
	if len([]byte(strings.TrimSpace(secret))) < MinimumTokenSecretBytes {
		return fmt.Errorf("token secret must be at least %d bytes", MinimumTokenSecretBytes)
	}
	return nil
}

func (manager *TokenManager) sign(message string) []byte {
	hasher := hmac.New(sha256.New, manager.secret)
	_, _ = hasher.Write([]byte(message))
	return hasher.Sum(nil)
}

func encode(value []byte) string { return base64.RawURLEncoding.EncodeToString(value) }
