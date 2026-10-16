package minio

import (
	"crypto/sha256"
	"encoding/hex"
	"testing"
)

func TestNewObjectStoreRejectsNilPool(t *testing.T) {
	if _, err := NewObjectStore(nil, nil, Config{}); err == nil {
		t.Fatal("NewObjectStore() accepted a nil PostgreSQL pool")
	}
}

func TestNewMinIOObjectKeyPassesStorageKeyValidation(t *testing.T) {
	key, err := newMinIOObjectKey()
	if err != nil {
		t.Fatalf("newMinIOObjectKey() error = %v", err)
	}
	if err := validateStorageObjectKey(key); err != nil {
		t.Fatalf("validateStorageObjectKey(%q) error = %v", key, err)
	}
}

func TestStorageKeyValidationAcceptsPostgreSQLKeysAndRejectsOtherKeys(t *testing.T) {
	for _, key := range []string{
		"db/v1/0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		"minio/v1/0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
	} {
		if err := validateStorageObjectKey(key); err != nil {
			t.Fatalf("validateStorageObjectKey(%q) error = %v", key, err)
		}
	}
	for _, key := range []string{"unknown/v1/0123456789abcdef", "minio/v1/../object", "minio/v1/ABCDEF"} {
		if err := validateStorageObjectKey(key); err == nil {
			t.Errorf("validateStorageObjectKey(%q) accepted an invalid key", key)
		}
	}
}

func TestValidateContentEnforcesSizeChecksumAndDetectedType(t *testing.T) {
	content := []byte("private document content")
	checksum := sha256.Sum256(content)
	checksumText := hex.EncodeToString(checksum[:])
	contentType := "text/plain; charset=utf-8"

	if _, err := validateContent(content, contentType, int64(len(content)), checksumText, 1024); err != nil {
		t.Fatalf("validateContent() error = %v", err)
	}
	for name, values := range map[string]struct {
		content     []byte
		contentType string
		sizeBytes   int64
		checksum    string
	}{
		"too large": {
			content: content, contentType: contentType, sizeBytes: int64(len(content)), checksum: checksumText,
		},
		"bad size": {
			content: content, contentType: contentType, sizeBytes: int64(len(content) + 1), checksum: checksumText,
		},
		"bad checksum": {
			content: content, contentType: contentType, sizeBytes: int64(len(content)), checksum: "wrong",
		},
		"bad content type": {
			content: content, contentType: "image/png", sizeBytes: int64(len(content)), checksum: checksumText,
		},
	} {
		t.Run(name, func(t *testing.T) {
			maxBytes := int64(1024)
			if name == "too large" {
				maxBytes = int64(len(content) - 1)
			}
			if _, err := validateContent(values.content, values.contentType, values.sizeBytes, values.checksum, maxBytes); err == nil {
				t.Fatal("validateContent() accepted invalid content")
			}
		})
	}
}
