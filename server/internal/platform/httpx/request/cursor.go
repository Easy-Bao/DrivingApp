package request

import (
	"encoding/base64"
	"encoding/json"
	"math"
	"net/url"
	"time"
)

// CursorPagination is selected by supplying cursor, including cursor= for the
// first page. Offset remains available to older callers, but cannot be mixed
// with a continuation. Cursors describe a boundary, not a frozen snapshot:
// rows that change filter membership may enter or leave subsequent pages.
type CursorPagination struct {
	OffsetPagination
	Enabled         bool
	BeforeCreatedAt time.Time
	BeforeID        int
}

type listCursor struct {
	Scope     string    `json:"scope"`
	CreatedAt time.Time `json:"created_at"`
	ID        int       `json:"id"`
}

func ParseCursorPagination(values url.Values, defaultLimit, maxLimit int, scope string) (CursorPagination, error) {
	offset, err := ParseOffsetPagination(values, defaultLimit, maxLimit)
	if err != nil {
		return CursorPagination{}, err
	}
	page := CursorPagination{OffsetPagination: offset, Enabled: values.Has("cursor")}
	if !page.Enabled {
		return page, nil
	}
	if page.Offset != 0 || len(values["cursor"]) != 1 {
		return CursorPagination{}, ErrInvalidPagination
	}
	raw := values.Get("cursor")
	if raw == "" {
		return page, nil
	}
	if len(raw) > 512 {
		return CursorPagination{}, ErrInvalidPagination
	}
	data, err := base64.RawURLEncoding.DecodeString(raw)
	if err != nil {
		return CursorPagination{}, ErrInvalidPagination
	}
	var cursor listCursor
	if err := json.Unmarshal(data, &cursor); err != nil || cursor.Scope != scope || cursor.CreatedAt.IsZero() || cursor.ID <= 0 || cursor.ID > math.MaxInt32 {
		return CursorPagination{}, ErrInvalidPagination
	}
	page.BeforeCreatedAt, page.BeforeID = cursor.CreatedAt, cursor.ID
	return page, nil
}

func EncodeListCursor(scope, createdAt string, id int) (string, error) {
	timestamp, err := time.Parse(time.RFC3339Nano, createdAt)
	if err != nil || timestamp.IsZero() || id <= 0 || id > math.MaxInt32 {
		return "", ErrInvalidPagination
	}
	data, err := json.Marshal(listCursor{Scope: scope, CreatedAt: timestamp, ID: id})
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(data), nil
}
