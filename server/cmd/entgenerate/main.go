package main

import (
	"fmt"
	"io/fs"
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"entgo.io/ent/entc"
	"entgo.io/ent/entc/gen"
)

// The Ent graph is generated from schemas owned by their business modules.
// The platform aggregate is generated metadata only; no business code should
// add schemas there. Keeping it stable is required because Ent's generated
// runtime references schema descriptors for field validators.
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
	if err := os.RemoveAll(aggregate); err != nil {
		return fmt.Errorf("remove generated schema aggregate: %w", err)
	}
	if err := os.MkdirAll(aggregate, 0o755); err != nil {
		return fmt.Errorf("create generated schema aggregate: %w", err)
	}

	type schemaModule struct {
		sourcePath   string
		outputPrefix string
	}
	modules := []schemaModule{
		{sourcePath: "auth", outputPrefix: "auth"},
		{sourcePath: "users", outputPrefix: "users"},
		{sourcePath: "driver/documents", outputPrefix: "driver_documents"},
		{sourcePath: "rides", outputPrefix: "rides"},
		{sourcePath: "admin", outputPrefix: "admin"},
		{sourcePath: "platform/storage", outputPrefix: "platform_storage"},
	}
	for _, module := range modules {
		source := filepath.Join(root, "internal", module.sourcePath, "schema")
		err = filepath.WalkDir(source, func(path string, entry fs.DirEntry, walkErr error) error {
			if walkErr != nil {
				return walkErr
			}
			if entry.IsDir() || filepath.Ext(path) != ".go" || strings.HasSuffix(entry.Name(), "_test.go") {
				return nil
			}
			contents, readErr := os.ReadFile(path)
			if readErr != nil {
				return readErr
			}
			return os.WriteFile(filepath.Join(aggregate, module.outputPrefix+"_"+entry.Name()), contents, 0o644)
		})
		if err != nil {
			return fmt.Errorf("copy %s schemas: %w", module.sourcePath, err)
		}
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
