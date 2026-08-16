package security

import (
	"strings"
	"testing"
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

func TestTokenManagerSeparatesRefreshTokensFromAccessTokens(t *testing.T) {
	manager := NewTokenManager("test-secret")
	refreshToken, err := manager.IssueRefreshWithRole("user-7", "passenger")
	if err != nil {
		t.Fatalf("IssueRefreshWithRole() returned error: %v", err)
	}

	identity, err := manager.VerifyRefresh(refreshToken)
	if err != nil || identity.Subject != "user-7" || identity.Role != "passenger" {
		t.Fatalf("refresh identity = %#v, %v", identity, err)
	}
	if _, err := manager.Verify(refreshToken); err == nil {
		t.Fatal("expected refresh token to be rejected as an access token")
	}

	accessToken, err := manager.IssueWithRole("user-7", "passenger")
	if err != nil {
		t.Fatalf("IssueWithRole() returned error: %v", err)
	}
	if _, err := manager.VerifyRefresh(accessToken); err == nil {
		t.Fatal("expected access token to be rejected as a refresh token")
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
