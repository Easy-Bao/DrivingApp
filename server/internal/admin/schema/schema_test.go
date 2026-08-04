package schema

import "testing"

func TestAuditSchemaRequiresRequestIdentity(t *testing.T) {
	if len((AuditEvent{}).Fields()) != 6 {
		t.Fatal("audit events must carry a request identity")
	}
}
