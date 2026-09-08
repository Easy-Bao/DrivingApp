package postgres

import (
	"errors"
	"fmt"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"
)

func TestNewObjectStoreRejectsNilPool(t *testing.T) {
	if _, err := NewObjectStore(nil); err == nil {
		t.Fatal("expected nil PostgreSQL pool to be rejected")
	}
}

func TestGeneratedObjectKeyPassesValidation(t *testing.T) {
	key, err := newObjectKey()
	if err != nil {
		t.Fatalf("newObjectKey() error = %v", err)
	}
	if err := validateObjectKey(key); err != nil {
		t.Fatalf("validateObjectKey(%q) error = %v", key, err)
	}
}

func TestIsPostgresObjectUniqueViolationFindsWrappedConstraint(t *testing.T) {
	err := fmt.Errorf("insert private object: %w", &pgconn.PgError{Code: "23505"})
	if !isPostgresObjectUniqueViolation(err) {
		t.Fatal("expected wrapped unique violation to be detected")
	}
	if isPostgresObjectUniqueViolation(errors.New("connection failed")) {
		t.Fatal("unexpected unique violation for unrelated error")
	}
}
