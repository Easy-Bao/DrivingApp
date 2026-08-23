package migration_test

import (
	"testing"

	entschema "entgo.io/ent/dialect/sql/schema"
	entmigrate "github.com/Easy-Bao/DrivingApp/server/ent/migrate"
)

func TestRideCreatedAtHasDatabaseBackfillDefault(t *testing.T) {
	createdAt, exists := entmigrate.RidesTable.Column("created_at")
	if !exists {
		t.Fatal("rides.created_at is missing from the generated schema")
	}
	expression, exists := createdAt.Default.(entschema.Expr)
	if !exists {
		t.Fatalf("rides.created_at default = %T, want a database expression", createdAt.Default)
	}
	if expression != "CURRENT_TIMESTAMP" {
		t.Fatalf("rides.created_at default = %q, want CURRENT_TIMESTAMP", expression)
	}
}

func TestRideEarningsQueriesHaveACompositeIndex(t *testing.T) {
	wanted := map[string]bool{
		"ride_driver_id_status_completed_at":    false,
		"ride_passenger_id_status_completed_at": false,
	}
	for _, index := range entmigrate.RidesTable.Indexes {
		if _, exists := wanted[index.Name]; exists {
			wanted[index.Name] = true
		}
	}
	for name, exists := range wanted {
		if !exists {
			t.Fatalf("rides reporting index %q is missing from the generated schema", name)
		}
	}
}
