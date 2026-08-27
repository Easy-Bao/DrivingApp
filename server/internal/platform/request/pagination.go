package request

import (
	"errors"
	"net/url"
	"strconv"
)

var ErrInvalidPagination = errors.New("invalid pagination")

type OffsetPagination struct {
	Limit  int
	Offset int
}

func ParseOffsetPagination(values url.Values, defaultLimit, maxLimit int) (OffsetPagination, error) {
	if defaultLimit <= 0 || maxLimit < defaultLimit {
		return OffsetPagination{}, ErrInvalidPagination
	}
	page := OffsetPagination{Limit: defaultLimit}
	if values.Has("limit") {
		limit, err := strconv.Atoi(values.Get("limit"))
		if err != nil || limit <= 0 || limit > maxLimit {
			return OffsetPagination{}, ErrInvalidPagination
		}
		page.Limit = limit
	}
	if values.Has("offset") {
		offset, err := strconv.Atoi(values.Get("offset"))
		if err != nil || offset < 0 || offset > 1_000_000 {
			return OffsetPagination{}, ErrInvalidPagination
		}
		page.Offset = offset
	}
	return page, nil
}
