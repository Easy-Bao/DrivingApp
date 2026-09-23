package postgres

import (
	"encoding/hex"
	"testing"
)

func TestNewAuditRequestIDReturnsUniqueHexValue(t *testing.T) {
	first, err := newAuditRequestID()
	if err != nil {
		t.Fatalf("newAuditRequestID() error = %v", err)
	}
	second, err := newAuditRequestID()
	if err != nil {
		t.Fatalf("newAuditRequestID() error = %v", err)
	}
	if len(first) != 32 || len(second) != 32 {
		t.Fatalf("request IDs = %q, %q; want 32 hex characters", first, second)
	}
	if _, err := hex.DecodeString(first); err != nil {
		t.Fatalf("first request ID is not hexadecimal: %v", err)
	}
	if _, err := hex.DecodeString(second); err != nil {
		t.Fatalf("second request ID is not hexadecimal: %v", err)
	}
	if first == second {
		t.Fatal("expected consecutive request IDs to be unique")
	}
}
