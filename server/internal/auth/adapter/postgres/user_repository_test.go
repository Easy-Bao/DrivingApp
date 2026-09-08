package postgres

import (
	"errors"
	"fmt"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestNewPostgresUserRepositoryRejectsNilPool(t *testing.T) {
	if _, err := NewPostgresUserRepository(nil); err == nil {
		t.Fatal("expected nil PostgreSQL pool to be rejected")
	}
}

func TestValidateUserRole(t *testing.T) {
	for _, role := range []domain.Role{domain.Driver, domain.Passenger} {
		if err := validateUserRole(role); err != nil {
			t.Errorf("validateUserRole(%q) = %v", role, err)
		}
	}

	if err := validateUserRole("admin"); !errors.Is(err, domain.ErrInvalidRole) {
		t.Fatalf("validateUserRole(admin) = %v, want invalid role", err)
	}
}

func TestTextValue(t *testing.T) {
	if got := textValue(pgtype.Text{String: "Ada", Valid: true}); got != "Ada" {
		t.Fatalf("valid text = %q, want Ada", got)
	}
	if got := textValue(pgtype.Text{}); got != "" {
		t.Fatalf("invalid text = %q, want empty string", got)
	}
}

func TestFromPostgresUserMapsNullableName(t *testing.T) {
	account := fromPostgresUser(databasepostgres.User{
		ID:           7,
		Name:         pgtype.Text{String: "Ada", Valid: true},
		Email:        "ada@example.com",
		Phone:        "+639000000000",
		PasswordHash: "hash",
		Role:         string(domain.Passenger),
		IsVerified:   true,
	})

	if account.ID != 7 || account.Name != "Ada" || account.Role != domain.Passenger || !account.IsVerified {
		t.Fatalf("mapped account = %+v", account)
	}
}

func TestIsPostgresUniqueViolationFindsWrappedConstraint(t *testing.T) {
	err := fmt.Errorf("insert user: %w", &pgconn.PgError{Code: "23505"})
	if !isPostgresUniqueViolation(err) {
		t.Fatal("expected wrapped unique violation to be detected")
	}
	if isPostgresUniqueViolation(errors.New("connection failed")) {
		t.Fatal("unexpected unique violation for unrelated error")
	}
}
