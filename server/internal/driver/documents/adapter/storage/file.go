package storage

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

const objectKeyBytes = 32

type FileStorage struct {
	root string
}

func NewFileStorage(root string) (*FileStorage, error) {
	root = strings.TrimSpace(root)
	if root == "" {
		return nil, fmt.Errorf("private document storage directory is required")
	}
	absoluteRoot, err := filepath.Abs(root)
	if err != nil {
		return nil, fmt.Errorf("resolve private document storage directory: %w", err)
	}
	if err := os.MkdirAll(absoluteRoot, 0o700); err != nil {
		return nil, fmt.Errorf("create private document storage directory: %w", err)
	}
	rootInfo, err := os.Lstat(absoluteRoot)
	if err != nil || !rootInfo.IsDir() {
		return nil, fmt.Errorf("private document storage root must be a directory")
	}
	if err := os.Chmod(absoluteRoot, 0o700); err != nil {
		return nil, fmt.Errorf("secure private document storage directory: %w", err)
	}
	return &FileStorage{root: absoluteRoot}, nil
}

func (storage *FileStorage) Store(ctx context.Context, content []byte) (string, error) {
	if storage == nil || storage.root == "" || len(content) == 0 {
		return "", fmt.Errorf("private document storage is not configured")
	}
	if err := ctx.Err(); err != nil {
		return "", err
	}
	for attempt := 0; attempt < 3; attempt++ {
		key, err := newObjectKey()
		if err != nil {
			return "", err
		}
		path, err := storage.pathForKey(key)
		if err != nil {
			return "", err
		}
		shard := filepath.Dir(path)
		if err := os.MkdirAll(shard, 0o700); err != nil {
			return "", fmt.Errorf("create private document shard: %w", err)
		}
		shardInfo, err := os.Lstat(shard)
		if err != nil || !shardInfo.IsDir() {
			return "", fmt.Errorf("private document shard must be a directory")
		}
		if err := os.Chmod(shard, 0o700); err != nil {
			return "", fmt.Errorf("secure private document shard: %w", err)
		}
		file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
		if errors.Is(err, os.ErrExist) {
			continue
		}
		if err != nil {
			return "", fmt.Errorf("create private document object: %w", err)
		}
		var written int
		if written, err = file.Write(content); err == nil && written != len(content) {
			err = io.ErrShortWrite
		}
		if err == nil {
			err = file.Sync()
		}
		closeErr := file.Close()
		if err == nil {
			err = closeErr
		}
		if err != nil {
			_ = os.Remove(path)
			return "", fmt.Errorf("write private document object: %w", err)
		}
		return key, nil
	}
	return "", fmt.Errorf("allocate unique private document object key")
}

func (storage *FileStorage) Read(ctx context.Context, key string, maxBytes int64) ([]byte, error) {
	if maxBytes <= 0 {
		return nil, fmt.Errorf("private document read limit must be positive")
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	path, err := storage.pathForKey(key)
	if err != nil {
		return nil, err
	}
	info, err := os.Lstat(path)
	if err != nil {
		return nil, fmt.Errorf("inspect private document object: %w", err)
	}
	if !info.Mode().IsRegular() || info.Size() <= 0 || info.Size() > maxBytes {
		return nil, fmt.Errorf("private document object has an invalid size or type")
	}
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open private document object: %w", err)
	}
	defer file.Close()
	content, err := io.ReadAll(io.LimitReader(file, maxBytes+1))
	if err != nil {
		return nil, fmt.Errorf("read private document object: %w", err)
	}
	if int64(len(content)) > maxBytes {
		return nil, fmt.Errorf("private document object exceeds the read limit")
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	return content, nil
}

func (storage *FileStorage) Delete(ctx context.Context, key string) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	path, err := storage.pathForKey(key)
	if err != nil {
		return err
	}
	if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("delete private document object: %w", err)
	}
	return nil
}

func (storage *FileStorage) pathForKey(key string) (string, error) {
	if storage == nil || storage.root == "" {
		return "", fmt.Errorf("private document storage is not configured")
	}
	parts := strings.Split(key, "/")
	if len(parts) != 3 || parts[0] != "v1" || len(parts[1]) != 2 || len(parts[2]) != objectKeyBytes*2 || parts[1] != parts[2][:2] {
		return "", fmt.Errorf("invalid private document object key")
	}
	decoded, err := hex.DecodeString(parts[2])
	if err != nil || len(decoded) != objectKeyBytes || parts[2] != strings.ToLower(parts[2]) {
		return "", fmt.Errorf("invalid private document object key")
	}
	return filepath.Join(storage.root, parts[1], parts[2]), nil
}

func newObjectKey() (string, error) {
	random := make([]byte, objectKeyBytes)
	if _, err := rand.Read(random); err != nil {
		return "", fmt.Errorf("generate private document object key: %w", err)
	}
	encoded := hex.EncodeToString(random)
	return "v1/" + encoded[:2] + "/" + encoded, nil
}
