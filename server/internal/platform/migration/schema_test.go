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

func TestDriverDocumentsCarryPrivateObjectIntegrityMetadata(t *testing.T) {
	for _, column := range []string{
		"content_type",
		"size_bytes",
		"checksum_sha256",
		"created_at",
		"reviewed_at",
		"reviewed_by",
	} {
		if _, exists := entmigrate.DriverDocumentsTable.Column(column); !exists {
			t.Fatalf("driver_documents.%s is missing from the generated schema", column)
		}
	}
	wantedIndexes := map[string]bool{
		"driver_document_driver_type_created_at": false,
		"driver_document_status_created_at":      false,
	}
	for _, index := range entmigrate.DriverDocumentsTable.Indexes {
		if _, exists := wantedIndexes[index.Name]; exists {
			wantedIndexes[index.Name] = true
		}
	}
	for name, exists := range wantedIndexes {
		if !exists {
			t.Fatalf("driver document index %q is missing", name)
		}
	}
}

func TestPassengerProfilesCarryProfileAttributes(t *testing.T) {
	for _, column := range []string{
		"gender",
		"avatar_storage_key",
		"avatar_content_type",
	} {
		if _, exists := entmigrate.PassengerProfilesTable.Column(column); !exists {
			t.Fatalf("passenger_profiles.%s is missing from the generated schema", column)
		}
	}
}
