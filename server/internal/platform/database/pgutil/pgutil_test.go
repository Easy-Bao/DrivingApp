package pgutil

import (
	"errors"
	"fmt"
	"math"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestToPositiveInt32(t *testing.T) {
	got, err := ToPositiveInt32(42, "ride id")
	if err != nil || got != 42 {
		t.Fatalf("ToPositiveInt32(42) = (%d, %v), want (42, nil)", got, err)
	}
	if _, err := ToPositiveInt32(0, "ride id"); err == nil {
		t.Fatal("expected error for zero id")
	}
	if _, err := ToPositiveInt32(-1, "ride id"); err == nil {
		t.Fatal("expected error for negative id")
	}
	if math.MaxInt > math.MaxInt32 {
		if _, err := ToPositiveInt32(math.MaxInt32+1, "ride id"); err == nil {
			t.Fatal("expected error for int32 overflow")
		}
	}
}

func TestToPositiveInt32s(t *testing.T) {
	got, err := ToPositiveInt32s([]int{1, 2, 3}, "driver id")
	if err != nil || len(got) != 3 || got[0] != 1 || got[2] != 3 {
		t.Fatalf("ToPositiveInt32s = (%v, %v)", got, err)
	}
	if _, err := ToPositiveInt32s([]int{1, 0}, "driver id"); err == nil {
		t.Fatal("expected error when slice contains non-positive id")
	}
}

func TestToNonNegativeInt32AndToInt32(t *testing.T) {
	if got, err := ToNonNegativeInt32(0, "offset"); err != nil || got != 0 {
		t.Fatalf("ToNonNegativeInt32(0) = (%d, %v)", got, err)
	}
	if _, err := ToNonNegativeInt32(-1, "offset"); err == nil {
		t.Fatal("expected error for negative offset")
	}
	if got, err := ToInt32(-5, "user id"); err != nil || got != -5 {
		t.Fatalf("ToInt32(-5) = (%d, %v)", got, err)
	}
}

func TestTextAndTimestamptzHelpers(t *testing.T) {
	if text := ToText(""); !text.Valid || text.String != "" {
		t.Fatalf("ToText(\"\") = %#v", text)
	}
	if text := ToNonEmptyText(""); text.Valid {
		t.Fatalf("ToNonEmptyText(\"\") = %#v, want invalid", text)
	}
	if text := ToNonEmptyText("ok"); !text.Valid || text.String != "ok" {
		t.Fatalf("ToNonEmptyText(\"ok\") = %#v", text)
	}
	if got := TextValue(pgtype.Text{}); got != "" {
		t.Fatalf("TextValue(NULL) = %q", got)
	}
	if got := TextValue(pgtype.Text{String: "abc", Valid: true}); got != "abc" {
		t.Fatalf("TextValue(abc) = %q", got)
	}
	now := time.Now().UTC()
	ts := ToTimestamptz(now)
	if !ts.Valid || !ts.Time.Equal(now) {
		t.Fatalf("ToTimestamptz = %#v", ts)
	}
}

func TestUniqueViolation(t *testing.T) {
	uniqueErr := fmt.Errorf("wrap: %w", &pgconn.PgError{Code: "23505", ConstraintName: "users_email_key"})
	constraint, ok := UniqueConstraint(uniqueErr)
	if !ok || constraint != "users_email_key" {
		t.Fatalf("UniqueConstraint = (%q, %v)", constraint, ok)
	}
	if !IsUniqueViolation(uniqueErr) {
		t.Fatal("expected IsUniqueViolation true")
	}
	otherErr := errors.New("other")
	if IsUniqueViolation(otherErr) {
		t.Fatal("expected IsUniqueViolation false for non-pg error")
	}
}
