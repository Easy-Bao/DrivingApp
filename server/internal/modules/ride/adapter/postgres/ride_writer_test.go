package postgres

import (
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
)

func TestPostgresRideValuesRemainPresentWhenZeroValued(t *testing.T) {
	if value := rideFloat(0); !value.Valid || value.Float64 != 0 {
		t.Fatalf("rideFloat(0) = %+v", value)
	}
	if value := pgutil.ToText(""); !value.Valid || value.String != "" {
		t.Fatalf("pgutil.ToText(\"\") = %+v", value)
	}
}
