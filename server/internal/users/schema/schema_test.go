package schema

import "testing"

func TestProfileSchemasDeclareSeparateRoles(t *testing.T) {
	if len((PassengerProfile{}).Fields()) == 0 || len((DriverProfile{}).Fields()) == 0 {
		t.Fatal("passenger and driver profiles must own their fields")
	}
}
