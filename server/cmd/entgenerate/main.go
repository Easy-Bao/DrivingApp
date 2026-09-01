package main

import (
	"fmt"
	"log/slog"
	"os"
	"path/filepath"

	"entgo.io/ent/entc"
	"entgo.io/ent/entc/gen"
)

// The Ent graph is generated from the handwritten schemas in ent/schema.
// The rest of server/ent is generated output; keeping the source schemas next
// to that output follows Ent's conventional project layout without mixing
// persistence definitions into the application packages.
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
	schemaPath := filepath.Join(root, "ent", "schema")
	if _, err := os.Stat(schemaPath); err != nil {
		return fmt.Errorf("resolve canonical Ent schema directory: %w", err)
	}

	if err := entc.Generate(schemaPath, &gen.Config{
		Target:   filepath.Join(root, "ent"),
		Package:  "github.com/Easy-Bao/DrivingApp/server/ent",
		Features: []gen.Feature{gen.FeatureLock},
	}); err != nil {
		return fmt.Errorf("generate ent graph: %w", err)
	}
	return nil
}
