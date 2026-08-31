package main

import (
	"fmt"
	"log/slog"
	"os"
	"path/filepath"

	"entgo.io/ent/entc"
	"entgo.io/ent/entc/gen"
)

// The Ent graph is generated from the canonical platform schema directory.
// Keeping schema ownership in one place prevents feature packages from
// drifting apart while Ent's generated runtime references those descriptors
// for field validators.
func main() {
	if err := run(); err != nil {
		slog.Error("ent generation command failed", "error", err)
		os.Exit(1)
	}
}

func run() error {
	workingDirectory, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("get working directory: %w", err)
	}
	root, err := filepath.Abs(filepath.Join(workingDirectory, ".."))
	if err != nil {
		return fmt.Errorf("resolve project root: %w", err)
	}
	aggregate := filepath.Join(root, "internal", "platform", "ent", "schema")
	if _, err := os.Stat(aggregate); err != nil {
		return fmt.Errorf("resolve canonical Ent schema directory: %w", err)
	}

	if err := entc.Generate(aggregate, &gen.Config{
		Target:   filepath.Join(root, "ent"),
		Package:  "github.com/Easy-Bao/DrivingApp/server/ent",
		Features: []gen.Feature{gen.FeatureLock},
	}); err != nil {
		return fmt.Errorf("generate ent graph: %w", err)
	}
	return nil
}
