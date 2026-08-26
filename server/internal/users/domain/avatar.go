package domain

import (
	"context"
	"errors"
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

type AvatarStorage interface {
	Store(ctx context.Context, content []byte) (string, error)
	Read(ctx context.Context, key string, maxBytes int64) ([]byte, error)
	Delete(ctx context.Context, key string) error
}
