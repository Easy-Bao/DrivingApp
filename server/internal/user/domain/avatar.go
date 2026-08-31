package domain

import (
	"context"
	"errors"

	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
)

const MaxAvatarBytes int64 = 2 << 20

var (
	ErrInvalidAvatar            = errors.New("invalid passenger avatar")
	ErrAvatarNotFound           = errors.New("passenger avatar not found")
	ErrAvatarCorrupt            = errors.New("passenger avatar failed integrity validation")
	ErrAvatarStorageUnavailable = errors.New("passenger avatar storage is unavailable")
)

type Avatar struct {
	Bytes       []byte
	ContentType string
}

type AvatarRepository interface {
	SaveAvatar(ctx context.Context, userID int, content []byte, contentType string) (Profile, error)
	GetAvatar(ctx context.Context, userID int) (Avatar, error)
}

type AvatarStorage = platformstorage.ObjectStore
