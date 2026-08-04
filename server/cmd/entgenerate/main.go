package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"entgo.io/ent/entc"
	"entgo.io/ent/entc/gen"
)

// The Ent graph is generated from schemas owned by their business modules.
// The temporary aggregate is never committed and avoids a second global schema
// ownership directory while preserving one typed client and migration stream.
func main() {
	workingDirectory, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	root, err := filepath.Abs(filepath.Join(workingDirectory, ".."))
	if err != nil {
		panic(err)
	}
	workspace := filepath.Join(root, "internal", "ent", "schema")
	if err := os.MkdirAll(workspace, 0o755); err != nil {
		panic(err)
	}
	aggregate := workspace
	if err := os.RemoveAll(aggregate); err != nil {
		panic(err)
	}
	if err := os.MkdirAll(aggregate, 0o755); err != nil {
		panic(err)
	}

	modules := []string{"auth", "users", "driver_doc", "rides", "admin"}
	for _, module := range modules {
		source := filepath.Join(root, "internal", module, "schema")
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
			return os.WriteFile(filepath.Join(aggregate, module+"_"+entry.Name()), contents, 0o644)
		})
		if err != nil {
			panic(err)
		}
	}

	if err := entc.Generate(aggregate, &gen.Config{
		Target:  filepath.Join(root, "ent"),
		Package: "github.com/Easy-Bao/DrivingApp/server/ent",
	}); err != nil {
		panic(fmt.Errorf("generate Ent graph: %w", err))
	}
}
