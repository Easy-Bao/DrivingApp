package middleware

import (
	"strconv"
	"strings"
)

func positiveInt64Value(getenv func(string) string, key string, fallback int64) int64 {
	value, err := strconv.ParseInt(strings.TrimSpace(getenv(key)), 10, 64)
	if err != nil || value <= 0 {
		return fallback
	}
	return value
}
