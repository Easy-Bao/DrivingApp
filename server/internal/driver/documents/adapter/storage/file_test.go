package storage

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"testing"
)

func TestFileStorageCreatesDistinctImmutablePrivateObjects(t *testing.T) {
	root := filepath.Join(t.TempDir(), "documents")
	storage, err := NewFileStorage(root)
	if err != nil {
		t.Fatal(err)
	}
	firstKey, err := storage.Store(t.Context(), []byte("first"))
	if err != nil {
		t.Fatal(err)
	}
	secondKey, err := storage.Store(t.Context(), []byte("second"))
	if err != nil {
		t.Fatal(err)
	}
	if firstKey == secondKey {
		t.Fatal("separate revisions reused an object key")
	}
	first, err := storage.Read(t.Context(), firstKey, 16)
	if err != nil || string(first) != "first" {
		t.Fatalf("first object = %q, %v", first, err)
	}
	path, err := storage.pathForKey(firstKey)
	if err != nil {
		t.Fatal(err)
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("object mode = %o, want 600", info.Mode().Perm())
	}
}

func TestFileStorageRejectsTraversalAndOversizedReads(t *testing.T) {
	storage, err := NewFileStorage(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := storage.Read(t.Context(), "../../etc/passwd", 1024); err == nil {
		t.Fatal("path traversal key was accepted")
	}
	key, err := storage.Store(t.Context(), []byte("private"))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := storage.Read(t.Context(), key, 3); err == nil {
		t.Fatal("oversized object was read")
	}
	if err := storage.Delete(t.Context(), key); err != nil {
		t.Fatal(err)
	}
	if _, err := storage.Read(t.Context(), key, 16); err == nil {
		t.Fatal("deleted object remained readable")
	}
}

type legacyReaderFake struct {
	content []byte
	err     error
}

func (reader legacyReaderFake) Read(context.Context, string, int64) ([]byte, error) {
	return reader.content, reader.err
}

func TestCompatibleStorageUsesLegacyReaderOnlyForLegacyKeys(t *testing.T) {
	primary, err := NewFileStorage(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	storage := NewCompatibleStorage(primary, legacyReaderFake{content: []byte("legacy")})
	content, err := storage.Read(t.Context(), "driver:document:7:license", 16)
	if err != nil || string(content) != "legacy" {
		t.Fatalf("legacy content = %q, %v", content, err)
	}
	if _, err := storage.Read(t.Context(), "v1/invalid", 16); err == nil {
		t.Fatal("invalid primary key was delegated to legacy storage")
	}

	canceled, cancel := context.WithCancel(t.Context())
	cancel()
	if _, err := primary.Store(canceled, []byte("x")); !errors.Is(err, context.Canceled) {
		t.Fatalf("canceled store error = %v", err)
	}
}
