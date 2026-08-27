package security

import "testing"

func TestHashPasswordUsesSaltedWorkFactorAndVerifies(t *testing.T) {
	first, err := HashPassword("correct-horse")
	if err != nil {
		t.Fatalf("first hash: %v", err)
	}
	second, err := HashPassword("correct-horse")
	if err != nil {
		t.Fatalf("second hash: %v", err)
	}
	if first == second {
		t.Fatal("expected password hashes to use a random salt")
	}
	if !VerifyPassword(first, "correct-horse") {
		t.Fatal("expected password verification to succeed")
	}
	if VerifyPassword(first, "wrong-password") {
		t.Fatal("expected wrong password verification to fail")
	}
}

func TestVerifyPasswordAcceptsLegacyHashForMigration(t *testing.T) {
	legacy := legacyPasswordHash("legacy-password")
	if !IsLegacyPasswordHash(legacy) {
		t.Fatal("expected legacy SHA-256 fixture to be recognized")
	}
	if !VerifyPassword(legacy, "legacy-password") {
		t.Fatal("expected legacy password to remain verifiable")
	}
}

func TestHashPasswordRejectsBcryptOverflow(t *testing.T) {
	if _, err := HashPassword(string(make([]byte, 73))); err != ErrPasswordTooLong {
		t.Fatalf("expected ErrPasswordTooLong, got %v", err)
	}
}
