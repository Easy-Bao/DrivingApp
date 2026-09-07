package http

import (
	"errors"
	"fmt"
	"testing"

	"github.com/jackc/pgx/v5"
)

func TestIsProfileNotFoundRecognizesNativeDatabaseErrors(t *testing.T) {
	if !isProfileNotFound(fmt.Errorf("load profile: %w", pgx.ErrNoRows)) {
		t.Fatal("expected wrapped PostgreSQL no-rows error to be classified as not found")
	}
	if isProfileNotFound(errors.New("profile query failed")) {
		t.Fatal("unexpected not-found classification for unrelated error")
	}
}
