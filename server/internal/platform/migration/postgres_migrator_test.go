package migration

import (
	"testing"
	"testing/fstest"
)

func TestNewPostgresMigratorRejectsInvalidSourcePath(t *testing.T) {
	_, err := NewPostgresMigrator(
		fstest.MapFS{},
		"../migrations",
		nil,
		DefaultPostgresMigratorConfig(),
	)
	if err == nil {
		t.Fatal("expected invalid migration path to fail")
	}
}

func TestNewPostgresMigratorRequiresDatabase(t *testing.T) {
	_, err := NewPostgresMigrator(
		fstest.MapFS{},
		".",
		nil,
		DefaultPostgresMigratorConfig(),
	)
	if err == nil {
		t.Fatal("expected missing migration database to fail")
	}
}

func TestDefaultPostgresMigratorConfig(t *testing.T) {
	config := DefaultPostgresMigratorConfig()
	if config.MigrationsTable != "schema_migrations" {
		t.Fatalf("migration table = %q", config.MigrationsTable)
	}
	if err := config.validate(); err != nil {
		t.Fatalf("default config is invalid: %v", err)
	}
}
