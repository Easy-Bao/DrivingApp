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

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	MaxObjectBytes  = 10 << 20
	objectKeyBytes  = 32
	objectKeyPrefix = "db/v1/"
)

// ObjectStore stores private objects as PostgreSQL bytea values through the
// database adapter. It exposes opaque keys so owning feature modules retain
// authorization over the objects they reference.
type ObjectStore struct {
	pool    *pgxpool.Pool
	queries *databasepostgres.Queries
}

var _ platformstorage.ObjectStore = (*ObjectStore)(nil)

func NewObjectStore(pool *pgxpool.Pool) (*ObjectStore, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &ObjectStore{
		pool:    pool,
		queries: databasepostgres.New(pool),
	}, nil
}

func (store *ObjectStore) Store(ctx context.Context, content []byte) (string, error) {
	if err := store.validate(); err != nil {
		return "", err
	}
	if err := ctx.Err(); err != nil {
		return "", err
	}
	if len(content) == 0 || int64(len(content)) > MaxObjectBytes {
		return "", errors.New("private object has an invalid size")
	}

	checksum := sha256.Sum256(content)
	contentType := http.DetectContentType(content)
	for range 3 {
		key, err := newObjectKey()
		if err != nil {
			return "", err
		}
		err = store.queries.CreatePrivateObject(ctx, databasepostgres.CreatePrivateObjectParams{
			StorageKey:     key,
			Content:        append([]byte(nil), content...),
			ContentType:    contentType,
			SizeBytes:      int64(len(content)),
			ChecksumSha256: hex.EncodeToString(checksum[:]),
		})
		if err == nil {
			return key, nil
		}
		if !isPostgresObjectUniqueViolation(err) {
			return "", fmt.Errorf("create private object: %w", err)
		}
	}
	return "", errors.New("allocate unique private object key")
}

func (store *ObjectStore) Read(ctx context.Context, key string, maxBytes int64) ([]byte, error) {
	if err := store.validate(); err != nil {
		return nil, err
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

	object, err := store.queries.GetPrivateObjectByStorageKey(ctx, key)
	if err != nil {
		return nil, fmt.Errorf("query private object: %w", err)
	}
	invalidSize := object.SizeBytes <= 0 || object.SizeBytes > maxBytes
	contentSizeMismatch := int64(len(object.Content)) != object.SizeBytes
	if invalidSize || contentSizeMismatch {
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
	if err := store.validate(); err != nil {
		return err
	}
	if err := validateObjectKey(key); err != nil {
		return err
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	if err := store.queries.DeletePrivateObjectByStorageKey(ctx, key); err != nil {
		return fmt.Errorf("delete private object: %w", err)
	}
	return nil
}

func (store *ObjectStore) validate() error {
	if store == nil {
		return errors.New("postgresql object store is not configured")
	}
	if store.pool == nil || store.queries == nil {
		return errors.New("postgresql object store is not configured")
	}
	return nil
}

func isPostgresObjectUniqueViolation(err error) bool {
	var databaseError *pgconn.PgError
	return errors.As(err, &databaseError) && databaseError.Code == "23505"
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
