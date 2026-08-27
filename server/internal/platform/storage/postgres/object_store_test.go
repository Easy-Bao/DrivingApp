package postgres

import "testing"

func TestValidateObjectKey(t *testing.T) {
	valid := objectKeyPrefix + "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	if err := validateObjectKey(valid); err != nil {
		t.Fatalf("validateObjectKey(valid) error = %v", err)
	}

	for _, key := range []string{
		"",
		"v1/0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		objectKeyPrefix + "../secret",
		objectKeyPrefix + "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdeF",
		objectKeyPrefix + "0123456789abcdef",
	} {
		if err := validateObjectKey(key); err == nil {
			t.Errorf("validateObjectKey(%q) succeeded, want error", key)
		}
	}
}
