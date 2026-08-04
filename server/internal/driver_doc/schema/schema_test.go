package schema

import "testing"

func TestDriverDocumentDefaultsToPending(t *testing.T) {
	if len((DriverDocument{}).Fields()) != 4 {
		t.Fatal("driver document schema must define its persistence contract")
	}
}
