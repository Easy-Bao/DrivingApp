package pgutil

import (
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
)

const _uniqueViolationCode = "23505"

// ToPositiveInt32 converts a positive native int into a PostgreSQL int4 range value.
func ToPositiveInt32(value int, field string) (int32, error) {
	if value <= 0 || int64(value) > math.MaxInt32 {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

// ToPositiveInt32s converts a slice of positive native ints into PostgreSQL int4 values.
func ToPositiveInt32s(values []int, field string) ([]int32, error) {
	result := make([]int32, 0, len(values))
	for _, value := range values {
		converted, err := ToPositiveInt32(value, field)
		if err != nil {
			return nil, err
		}
		result = append(result, converted)
	}
	return result, nil
}

// ToNonNegativeInt32 converts a non-negative native int (e.g. limit/offset) into a PostgreSQL int4 value.
func ToNonNegativeInt32(value int, field string) (int32, error) {
	if value < 0 || int64(value) > math.MaxInt32 {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

// ToInt32 converts any signed native int fitting in int32 into a PostgreSQL int4 value.
func ToInt32(value int, field string) (int32, error) {
	if int64(value) < math.MinInt32 || int64(value) > math.MaxInt32 {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

// ToText wraps a string into a valid pgtype.Text value.
func ToText(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}

// ToNonEmptyText wraps a non-empty string into a valid pgtype.Text, or SQL NULL when empty.
func ToNonEmptyText(value string) pgtype.Text {
	if value == "" {
		return pgtype.Text{}
	}
	return ToText(value)
}

// TextValue extracts the underlying string from pgtype.Text, returning "" when NULL.
func TextValue(value pgtype.Text) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

// ToTimestamptz wraps a time.Time into a valid pgtype.Timestamptz value.
func ToTimestamptz(value time.Time) pgtype.Timestamptz {
	return pgtype.Timestamptz{Time: value, Valid: true}
}

// UniqueConstraint reports whether err is a PostgreSQL unique violation (23505) and returns its constraint name.
func UniqueConstraint(err error) (string, bool) {
	databaseError, ok := errors.AsType[*pgconn.PgError](err)
	if !ok || databaseError.Code != _uniqueViolationCode {
		return "", false
	}
	return databaseError.ConstraintName, true
}

// IsUniqueViolation reports whether err is a PostgreSQL unique violation (23505).
func IsUniqueViolation(err error) bool {
	_, ok := UniqueConstraint(err)
	return ok
}
