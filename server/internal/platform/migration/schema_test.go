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
