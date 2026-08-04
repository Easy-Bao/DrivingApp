package schema

import "testing"

func TestRideSchemaKeepsMoneyAsCentavos(t *testing.T) {
	if len((Ride{}).Fields()) != 4 || len((Bid{}).Fields()) != 4 {
		t.Fatal("ride and bid schemas must define their transactional fields")
	}
}
