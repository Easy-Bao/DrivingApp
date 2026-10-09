package minio

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
	storagepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/postgres"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	miniosdk "github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

const (
	MaxObjectBytes        = 10 << 20
	_objectKeyBytes       = 32
	_minioObjectKeyPrefix = "minio/v1/"
	_postgresObjectPrefix = "db/v1/"
	_objectCleanupTimeout = 5 * time.Second
)

type ObjectStore struct {
	client  *miniosdk.Client
	queries *databasepostgres.Queries
	legacy  platformstorage.ObjectStore
	config  Config
}

var _ platformstorage.ObjectStore = (*ObjectStore)(nil)

func NewObjectStore(ctx context.Context, pool *pgxpool.Pool, config Config) (*ObjectStore, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	if err := config.validate(); err != nil {
		return nil, err
	}
	if ctx == nil {
		ctx = context.Background()
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}

	client, err := miniosdk.New(config.Endpoint, &miniosdk.Options{
		Creds:  credentials.NewStaticV4(config.AccessKey, config.SecretKey, ""),
		Secure: config.Secure,
	})
	if err != nil {
		return nil, fmt.Errorf("create MinIO client: %w", err)
	}
	legacy, err := storagepostgres.NewObjectStore(pool)
	if err != nil {
		return nil, fmt.Errorf("create PostgreSQL object store: %w", err)
	}
	store := &ObjectStore{
		client:  client,
		queries: databasepostgres.New(pool),
		legacy:  legacy,
		config:  config,
	}
	if err := store.ensureBucket(ctx); err != nil {
		return nil, err
	}
	return store, nil
}

func (store *ObjectStore) Store(ctx context.Context, content []byte) (string, error) {
	if err := store.validate(); err != nil {
		return "", err
	}
	if err := ctx.Err(); err != nil {
		return "", err
	}
	if len(content) == 0 || len(content) > MaxObjectBytes {
		return "", errors.New("private object has an invalid size")
	}
	if !store.config.WriteEnabled {
		return store.legacy.Store(ctx, content)
	}

	checksum := sha256.Sum256(content)
	checksumText := hex.EncodeToString(checksum[:])
	contentType := http.DetectContentType(content)
	for range 3 {
		key, err := newMinIOObjectKey()
		if err != nil {
			return "", err
		}
		externalKey, err := newMinIOObjectKey()
		if err != nil {
			return "", err
		}

		if _, err := store.client.PutObject(
			ctx,
			store.config.Bucket,
			externalKey,
			bytes.NewReader(content),
			int64(len(content)),
			miniosdk.PutObjectOptions{ContentType: contentType},
		); err != nil {
			storeErr := fmt.Errorf("write private object to MinIO: %w", err)
			if cleanupErr := store.removeMinIOObject(context.WithoutCancel(ctx), externalKey); cleanupErr != nil {
				return "", errors.Join(
					storeErr,
					fmt.Errorf("clean up failed MinIO object write: %w", cleanupErr),
				)
			}
			return "", storeErr
		}

		err = store.queries.CreateExternalPrivateObject(ctx, databasepostgres.CreateExternalPrivateObjectParams{
			StorageKey:         key,
			ExternalStorageKey: textValue(externalKey),
			ContentType:        contentType,
			SizeBytes:          int64(len(content)),
			ChecksumSha256:     checksumText,
		})
		if err != nil {
			cleanupErr := store.removeMinIOObject(context.WithoutCancel(ctx), externalKey)
			if isPostgresObjectUniqueViolation(err) && cleanupErr == nil {
				continue
			}
			metadataErr := fmt.Errorf("create external private object metadata: %w", err)
			if cleanupErr != nil {
				return "", errors.Join(
					metadataErr,
					fmt.Errorf("clean up MinIO object without metadata: %w", cleanupErr),
				)
			}
			return "", metadataErr
		}
		return key, nil
	}
	return "", errors.New("allocate unique MinIO object key")
}

func (store *ObjectStore) Read(ctx context.Context, key string, maxBytes int64) ([]byte, error) {
	if err := store.validate(); err != nil {
		return nil, err
	}
	if maxBytes <= 0 {
		return nil, errors.New("private object read limit must be positive")
	}
	if err := validateStorageObjectKey(key); err != nil {
		return nil, err
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}

	object, err := store.queries.GetPrivateObjectByStorageKey(ctx, key)
	if err != nil {
		return nil, fmt.Errorf("query private object: %w", err)
	}
	if object.SizeBytes <= 0 || object.SizeBytes > maxBytes || object.SizeBytes > MaxObjectBytes {
		return nil, errors.New("private object has an invalid size")
	}

	if object.ExternalStorageKey.Valid {
		externalKey := object.ExternalStorageKey.String
		if err := validateStorageObjectKey(externalKey); err != nil {
			return nil, fmt.Errorf("private object has an invalid MinIO key: %w", err)
		}
		content, externalErr := store.readMinIO(ctx, externalKey, object.SizeBytes)
		if externalErr == nil {
			content, externalErr = validateContent(
				content,
				object.ContentType,
				object.SizeBytes,
				object.ChecksumSha256,
				maxBytes,
			)
			if externalErr == nil {
				return content, nil
			}
		}
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		if len(object.Content) > 0 {
			slog.WarnContext(ctx, "MinIO private object read failed; using PostgreSQL copy", "error", externalErr)
			return validateContent(
				object.Content,
				object.ContentType,
				object.SizeBytes,
				object.ChecksumSha256,
				maxBytes,
			)
		}
		return nil, fmt.Errorf("read private object from MinIO: %w", externalErr)
	}

	return validateContent(
		object.Content,
		object.ContentType,
		object.SizeBytes,
		object.ChecksumSha256,
		maxBytes,
	)
}

func (store *ObjectStore) Delete(ctx context.Context, key string) error {
	if err := store.validate(); err != nil {
		return err
	}
	if err := validateStorageObjectKey(key); err != nil {
		return err
	}
	if err := ctx.Err(); err != nil {
		return err
	}

	object, err := store.queries.GetPrivateObjectByStorageKey(ctx, key)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("query private object before deletion: %w", err)
	}
	if object.ExternalStorageKey.Valid {
		externalKey := object.ExternalStorageKey.String
		if err := validateStorageObjectKey(externalKey); err != nil {
			return fmt.Errorf("private object has an invalid MinIO key: %w", err)
		}
		if err := store.client.RemoveObject(ctx, store.config.Bucket, externalKey, miniosdk.RemoveObjectOptions{}); err != nil {
			return fmt.Errorf("delete private object from MinIO: %w", err)
		}
	}
	if err := store.queries.DeletePrivateObjectByStorageKey(ctx, key); err != nil {
		return fmt.Errorf("delete private object metadata: %w", err)
	}
	return nil
}

// MigrateLegacyObjects copies PostgreSQL-backed objects to MinIO one at a time.
// Each pointer is updated only after the stored bytes pass size, MIME, and
// checksum verification; the PostgreSQL copy remains available for fallback.
func (store *ObjectStore) MigrateLegacyObjects(ctx context.Context) (int64, error) {
	if err := store.validate(); err != nil {
		return 0, err
	}
	if err := ctx.Err(); err != nil {
		return 0, err
	}

	var migrated int64
	for {
		legacyObject, err := store.queries.GetNextPrivateObjectForExternalStorageMigration(ctx)
		if errors.Is(err, pgx.ErrNoRows) {
			return migrated, nil
		}
		if err != nil {
			return migrated, fmt.Errorf("find next PostgreSQL object to migrate: %w", err)
		}
		if !strings.HasPrefix(legacyObject.StorageKey, _postgresObjectPrefix) {
			return migrated, errors.New("pending private object does not use a PostgreSQL storage key")
		}
		content, err := validateContent(
			legacyObject.Content,
			legacyObject.ContentType,
			legacyObject.SizeBytes,
			legacyObject.ChecksumSha256,
			MaxObjectBytes,
		)
		if err != nil {
			return migrated, fmt.Errorf("validate PostgreSQL object before migration: %w", err)
		}
		if _, err := store.client.PutObject(
			ctx,
			store.config.Bucket,
			legacyObject.StorageKey,
			bytes.NewReader(content),
			int64(len(content)),
			miniosdk.PutObjectOptions{ContentType: legacyObject.ContentType},
		); err != nil {
			return migrated, fmt.Errorf("copy PostgreSQL object to MinIO: %w", err)
		}
		copiedContent, err := store.readMinIO(ctx, legacyObject.StorageKey, legacyObject.SizeBytes)
		if err != nil {
			return migrated, fmt.Errorf("verify copied MinIO object: %w", err)
		}
		if _, err := validateContent(
			copiedContent,
			legacyObject.ContentType,
			legacyObject.SizeBytes,
			legacyObject.ChecksumSha256,
			MaxObjectBytes,
		); err != nil {
			return migrated, fmt.Errorf("verify copied MinIO object integrity: %w", err)
		}
		updated, err := store.queries.SetPrivateObjectExternalStorageKey(ctx, databasepostgres.SetPrivateObjectExternalStorageKeyParams{
			ExternalStorageKey: textValue(legacyObject.StorageKey),
			ID:                 legacyObject.ID,
			SizeBytes:          legacyObject.SizeBytes,
			ChecksumSha256:     legacyObject.ChecksumSha256,
		})
		if err != nil {
			return migrated, fmt.Errorf("mark PostgreSQL object as copied to MinIO: %w", err)
		}
		if updated == 0 {
			current, err := store.queries.GetPrivateObjectByStorageKey(ctx, legacyObject.StorageKey)
			if err != nil || !current.ExternalStorageKey.Valid || current.ExternalStorageKey.String != legacyObject.StorageKey {
				return migrated, fmt.Errorf("mark copied MinIO object: metadata changed during migration")
			}
			continue
		}
		migrated++
	}
}

func (store *ObjectStore) ensureBucket(ctx context.Context) error {
	exists, err := store.client.BucketExists(ctx, store.config.Bucket)
	if err != nil {
		return fmt.Errorf("check MinIO bucket: %w", err)
	}
	if exists {
		return nil
	}
	if err := store.client.MakeBucket(ctx, store.config.Bucket, miniosdk.MakeBucketOptions{}); err != nil {
		exists, checkErr := store.client.BucketExists(ctx, store.config.Bucket)
		if checkErr != nil || !exists {
			return errors.Join(
				fmt.Errorf("create MinIO bucket: %w", err),
				checkErr,
			)
		}
	}
	return nil
}

func (store *ObjectStore) removeMinIOObject(ctx context.Context, key string) error {
	cleanupContext, cancel := context.WithTimeout(ctx, _objectCleanupTimeout)
	defer cancel()
	if err := store.client.RemoveObject(cleanupContext, store.config.Bucket, key, miniosdk.RemoveObjectOptions{}); err != nil {
		return fmt.Errorf("delete MinIO object: %w", err)
	}
	return nil
}

func (store *ObjectStore) readMinIO(ctx context.Context, key string, expectedSize int64) ([]byte, error) {
	object, err := store.client.GetObject(ctx, store.config.Bucket, key, miniosdk.GetObjectOptions{})
	if err != nil {
		return nil, fmt.Errorf("open MinIO object: %w", err)
	}
	defer object.Close()

	info, err := object.Stat()
	if err != nil {
		return nil, fmt.Errorf("stat MinIO object: %w", err)
	}
	if info.Size <= 0 || info.Size > MaxObjectBytes || info.Size != expectedSize {
		return nil, errors.New("MinIO object has an invalid size")
	}
	content, err := io.ReadAll(io.LimitReader(object, MaxObjectBytes+1))
	if err != nil {
		return nil, fmt.Errorf("read MinIO object: %w", err)
	}
	if int64(len(content)) != expectedSize {
		return nil, errors.New("MinIO object size does not match its metadata")
	}
	return content, nil
}

func (store *ObjectStore) validate() error {
	if store == nil || store.client == nil || store.queries == nil || store.legacy == nil {
		return errors.New("MinIO object store is not configured")
	}
	return nil
}

func validateContent(content []byte, contentType string, sizeBytes int64, checksumText string, maxBytes int64) ([]byte, error) {
	invalidSize := sizeBytes <= 0 || sizeBytes > maxBytes || sizeBytes > MaxObjectBytes
	contentSizeMismatch := int64(len(content)) != sizeBytes
	if invalidSize || contentSizeMismatch {
		return nil, errors.New("private object has an invalid size")
	}
	checksum := sha256.Sum256(content)
	if !strings.EqualFold(checksumText, hex.EncodeToString(checksum[:])) {
		return nil, errors.New("private object failed integrity validation")
	}
	if contentType != http.DetectContentType(content) {
		return nil, errors.New("private object failed content validation")
	}
	return append([]byte(nil), content...), nil
}

func validateStorageObjectKey(key string) error {
	if !strings.HasPrefix(key, _minioObjectKeyPrefix) && !strings.HasPrefix(key, _postgresObjectPrefix) {
		return errors.New("invalid private object key")
	}
	separator := strings.LastIndexByte(key, '/')
	encoded := key[separator+1:]
	if len(encoded) != _objectKeyBytes*2 || encoded != strings.ToLower(encoded) {
		return errors.New("invalid private object key")
	}
	decoded, err := hex.DecodeString(encoded)
	if err != nil || len(decoded) != _objectKeyBytes {
		return errors.New("invalid private object key")
	}
	return nil
}

func newMinIOObjectKey() (string, error) {
	random := make([]byte, _objectKeyBytes)
	if _, err := rand.Read(random); err != nil {
		return "", fmt.Errorf("generate MinIO object key: %w", err)
	}
	return _minioObjectKeyPrefix + hex.EncodeToString(random), nil
}

func textValue(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}

func isPostgresObjectUniqueViolation(err error) bool {
	var databaseError *pgconn.PgError
	return errors.As(err, &databaseError) && databaseError.Code == "23505"
}
