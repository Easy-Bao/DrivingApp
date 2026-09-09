package migrations

import (
	"io/fs"
	"strings"
	"testing"
)

func TestEmbeddedMigrationsHaveMatchingDirections(t *testing.T) {
	entries, err := fs.ReadDir(FS, ".")
	if err != nil {
		t.Fatalf("read embedded migrations: %v", err)
	}

	directionsByVersion := make(map[string]map[string]string)
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".sql") {
			continue
		}

		name := entry.Name()
		direction := ""
		switch {
		case strings.HasSuffix(name, ".up.sql"):
			direction = "up"
		case strings.HasSuffix(name, ".down.sql"):
			direction = "down"
		default:
			continue
		}

		separator := strings.IndexByte(name, '_')
		if separator <= 0 {
			t.Fatalf("migration %q has no numeric version prefix", name)
		}
		version := name[:separator]
		for _, digit := range version {
			if digit < '0' || digit > '9' {
				t.Fatalf("migration %q has a nonnumeric version prefix", name)
			}
		}
		directions := directionsByVersion[version]
		if directions == nil {
			directions = make(map[string]string, 2)
			directionsByVersion[version] = directions
		}
		if previous, exists := directions[direction]; exists {
			t.Fatalf("migration version %q has duplicate %s files: %q and %q", version, direction, previous, name)
		}
		directions[direction] = name
	}

	if len(directionsByVersion) == 0 {
		t.Fatal("no embedded migrations found")
	}
	for version, directions := range directionsByVersion {
		if _, exists := directions["up"]; !exists {
			t.Errorf("migration version %q has no up file", version)
		}
		if _, exists := directions["down"]; !exists {
			t.Errorf("migration version %q has no down file", version)
		}
	}
}
