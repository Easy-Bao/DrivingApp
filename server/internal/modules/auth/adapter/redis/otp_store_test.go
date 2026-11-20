package redis

import (
	"testing"
)

func TestOTPStoreCodeDigestIsKeyedAndDomainSeparated(t *testing.T) {
	unkeyed := NewOTPStore(nil)
	keyed := NewOTPStore(nil).WithHashSecret("test-hmac-secret")

	plain := "123456"
	d1 := keyed.codeDigest("reset", "User@Example.test", plain)
	d2 := keyed.codeDigest("reset", " user@example.test ", plain)
	if d1 == plain {
		t.Fatal("codeDigest must not return plaintext OTP")
	}
	if d1 != d2 {
		t.Fatalf("codeDigest did not normalize email: %q vs %q", d1, d2)
	}
	if d1 == keyed.codeDigest("verification", "user@example.test", plain) {
		t.Fatal("codeDigest must be domain-separated by purpose")
	}
	if d1 == keyed.codeDigest("reset", "other@example.test", plain) {
		t.Fatal("codeDigest must be domain-separated by email")
	}
	if d1 == unkeyed.codeDigest("reset", "user@example.test", plain) {
		t.Fatal("keyed HMAC digest must differ from unkeyed SHA-256 digest")
	}
}
