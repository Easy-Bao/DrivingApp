package schema

import "testing"

func TestUserSchemaDeclaresIdentityFields(t *testing.T) {
	fields := (User{}).Fields()
	if len(fields) < 5 {
		t.Fatalf("expected identity fields, got %d", len(fields))
	}
}
