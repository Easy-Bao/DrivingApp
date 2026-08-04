package security

import "testing"

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
