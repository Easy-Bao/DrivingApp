package token

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"testing"
	"time"
)

func TestVerifierReturnsSubject(t *testing.T) {
	verifier := NewVerifier("test-secret")
	token := sign("test-secret", `{"alg":"HS256"}`, fmt.Sprintf(`{"sub":"user-1","exp":%d}`, time.Now().Add(time.Minute).Unix()))
	subject, err := verifier.Verify(token)
	if err != nil || subject != "user-1" {
		t.Fatalf("Verify() = %q, %v", subject, err)
	}
}

func TestVerifierRejectsModifiedToken(t *testing.T) {
	verifier := NewVerifier("test-secret")
	token := sign("test-secret", `{"alg":"HS256"}`, fmt.Sprintf(`{"sub":"user-1","exp":%d}`, time.Now().Add(time.Minute).Unix())) + "x"
	if _, err := verifier.Verify(token); err == nil {
		t.Fatal("expected modified token to be rejected")
	}
}

func sign(secret, header, payload string) string {
	encode := base64.RawURLEncoding.EncodeToString
	message := encode([]byte(header)) + "." + encode([]byte(payload))
	mac := hmac.New(sha256.New, []byte(secret))
	_, _ = mac.Write([]byte(message))
	return message + "." + encode(mac.Sum(nil))
}
