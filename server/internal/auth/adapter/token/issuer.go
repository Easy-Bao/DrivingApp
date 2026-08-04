package token

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"time"
)

type Issuer struct {
	secret   string
	lifetime time.Duration
}

func NewIssuer(secret string) *Issuer { return &Issuer{secret: secret, lifetime: 24 * time.Hour} }
func (issuer *Issuer) Issue(subject string) (string, error) {
	if issuer.secret == "" {
		return "", fmt.Errorf("token secret is required")
	}
	header := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"HS256","typ":"JWT"}`))
	payload := base64.RawURLEncoding.EncodeToString([]byte(fmt.Sprintf(`{"sub":%q,"exp":%d}`, subject, time.Now().Add(issuer.lifetime).Unix())))
	mac := hmac.New(sha256.New, []byte(issuer.secret))
	_, _ = mac.Write([]byte(header + "." + payload))
	return header + "." + payload + "." + base64.RawURLEncoding.EncodeToString(mac.Sum(nil)), nil
}
