package postgres

import (
	"testing"
)

func TestPostgresRideValuesRemainPresentWhenZeroValued(t *testing.T) {
	if value := rideFloat(0); !value.Valid || value.Float64 != 0 {
		t.Fatalf("rideFloat(0) = %+v", value)
	}
	if value := rideText(""); !value.Valid || value.String != "" {
		t.Fatalf("rideText(\"\") = %+v", value)
	}
}
