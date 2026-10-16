package domain

import "errors"

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
