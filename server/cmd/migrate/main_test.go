package main

import (
	"context"
	"testing"
)

func TestRunRequiresDatabaseURL(t *testing.T) {
	t.Setenv("DATABASE_URL", "")

	if err := run(context.Background()); err == nil || err.Error() != "database url is required" {
		t.Fatalf("run() error = %v, want missing database url", err)
	}
}
