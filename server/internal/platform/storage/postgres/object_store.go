package postgres

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"net/http"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/privateobject"
	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
)

const (
	MaxObjectBytes  = 10 << 20
	objectKeyBytes  = 32
	objectKeyPrefix = "db/v1/"
)

var _ platformstorage.ObjectStore = (*ObjectStore)(nil)

// ObjectStore stores private objects as PostgreSQL bytea values through Ent.
// It deliberately exposes opaque keys instead of filesystem paths or public
// URLs, keeping authorization in the owning feature module.
type ObjectStore struct {
	client *ent.Client
}

func NewObjectStore(client *ent.Client) *ObjectStore {
	return &ObjectStore{client: client}
}

func (store *ObjectStore) Store(ctx context.Context, content []byte) (string, error) {
	if store == nil || store.client == nil {
		return "", errors.New("private object store is not configured")
	}
	if err := ctx.Err(); err != nil {
		return "", err
	}
	if len(content) == 0 || int64(len(content)) > MaxObjectBytes {
		return "", errors.New("private object has an invalid size")
	}

	checksum := sha256.Sum256(content)
	contentType := http.DetectContentType(content)
	for attempt := 0; attempt < 3; attempt++ {
		key, err := newObjectKey()
		if err != nil {
			return "", err
		}
		_, err = store.client.PrivateObject.Create().
			SetStorageKey(key).
			SetContent(append([]byte(nil), content...)).
			SetContentType(contentType).
			SetSizeBytes(int64(len(content))).
			SetChecksumSha256(hex.EncodeToString(checksum[:])).
			Save(ctx)
		if err == nil {
			return key, nil
		}
		if !ent.IsConstraintError(err) {
			return "", fmt.Errorf("create private object: %w", err)
		}
	}
	return "", errors.New("allocate unique private object key")
}

func (store *ObjectStore) Read(ctx context.Context, key string, maxBytes int64) ([]byte, error) {
	if store == nil || store.client == nil {
		return nil, errors.New("private object store is not configured")
	}
	if maxBytes <= 0 {
		return nil, errors.New("private object read limit must be positive")
	}
	if err := validateObjectKey(key); err != nil {
		return nil, err
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}

	object, err := store.client.PrivateObject.Query().
		Where(privateobject.StorageKeyEQ(key)).
		Only(ctx)
	if err != nil {
		return nil, fmt.Errorf("query private object: %w", err)
	}
	if object.SizeBytes <= 0 || object.SizeBytes > maxBytes || int64(len(object.Content)) != object.SizeBytes {
		return nil, errors.New("private object has an invalid size")
	}
	checksum := sha256.Sum256(object.Content)
	if !strings.EqualFold(object.ChecksumSha256, hex.EncodeToString(checksum[:])) {
		return nil, errors.New("private object failed integrity validation")
	}
	if detectedType := http.DetectContentType(object.Content); object.ContentType != detectedType {
		return nil, errors.New("private object failed content validation")
	}
	return append([]byte(nil), object.Content...), nil
}

func (store *ObjectStore) Delete(ctx context.Context, key string) error {
	if store == nil || store.client == nil {
		return errors.New("private object store is not configured")
	}
	if err := validateObjectKey(key); err != nil {
		return err
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	if _, err := store.client.PrivateObject.Delete().
		Where(privateobject.StorageKeyEQ(key)).
		Exec(ctx); err != nil {
		return fmt.Errorf("delete private object: %w", err)
	}
	return nil
}

func validateObjectKey(key string) error {
	if !strings.HasPrefix(key, objectKeyPrefix) {
		return errors.New("invalid private object key")
	}
	encoded := strings.TrimPrefix(key, objectKeyPrefix)
	if len(encoded) != objectKeyBytes*2 || encoded != strings.ToLower(encoded) {
		return errors.New("invalid private object key")
	}
	decoded, err := hex.DecodeString(encoded)
	if err != nil || len(decoded) != objectKeyBytes {
		return errors.New("invalid private object key")
	}
	return nil
}

func newObjectKey() (string, error) {
	random := make([]byte, objectKeyBytes)
	if _, err := rand.Read(random); err != nil {
		return "", fmt.Errorf("generate private object key: %w", err)
	}
	return objectKeyPrefix + hex.EncodeToString(random), nil
}
