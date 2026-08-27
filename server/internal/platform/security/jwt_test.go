package security

import (
	"errors"
	"strings"
	"testing"
	"time"
)

func TestTokenManagerIssuesAndVerifiesSubject(t *testing.T) {
	manager := NewTokenManager("test-secret")
	token, err := manager.Issue("user-7")
	if err != nil {
		t.Fatalf("issue token: %v", err)
	}
	subject, err := manager.Verify(token)
	if err != nil || subject != "user-7" {
		t.Fatalf("verify token = %q, %v", subject, err)
	}
}

func TestTokenManagerRejectsModifiedToken(t *testing.T) {
	manager := NewTokenManager("test-secret")
	token, err := manager.Issue("user-7")
	if err != nil {
		t.Fatalf("issue token: %v", err)
	}
	if _, err := manager.Verify(token + "x"); err == nil {
		t.Fatal("expected modified token to be rejected")
	}
}

func TestTokenManagerCarriesRoleAndRejectsUnexpectedHeader(t *testing.T) {
	manager := NewTokenManager("test-secret")
	token, err := manager.IssueWithRole("user-7", "driver")
	if err != nil {
		t.Fatalf("IssueWithRole() returned error: %v", err)
	}
	identity, err := manager.VerifyIdentity(token)
	if err != nil || identity.Subject != "user-7" || identity.Role != "driver" {
		t.Fatalf("identity = %#v, %v", identity, err)
	}

	parts := strings.Split(token, ".")
	parts[0] = encode([]byte(`{"alg":"none","typ":"JWT"}`))
	if _, err := manager.Verify(strings.Join(parts, ".")); err == nil {
		t.Fatal("expected token with an unexpected algorithm header to fail")
	}
}

func TestTokenManagerRejectsNonAccessTokenClaims(t *testing.T) {
	manager := NewTokenManager("test-secret")
	refreshToken, err := manager.issue("user-7", "passenger", "refresh", time.Hour)
	if err != nil {
		t.Fatalf("issue non-access token: %v", err)
	}
	if _, err := manager.Verify(refreshToken); err == nil {
		t.Fatal("expected non-access token to be rejected")
	}
}

func TestValidateTokenSecretRequiresProductionStrength(t *testing.T) {
	if err := ValidateTokenSecret("short-secret"); err == nil {
		t.Fatal("expected short token secret to be rejected")
	}
	if err := ValidateTokenSecret("01234567890123456789012345678901"); err != nil {
		t.Fatalf("expected 32-byte token secret to pass: %v", err)
	}
}

func TestNilTokenManagerFailsWithoutPanicking(t *testing.T) {
	var manager *TokenManager
	if _, err := manager.Issue("user-7"); err == nil {
		t.Fatal("expected nil token manager issue to fail")
	}
	if _, err := manager.Verify("token"); !errors.Is(err, ErrInvalidToken) {
		t.Fatalf("nil token manager verify error = %v, want invalid token", err)
	}
}
