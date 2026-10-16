package database

import (
	"context"
	"strings"
	"testing"
	"time"
)

func TestOpenPostgresMigrationDatabaseWithContextStopsBeforeOpeningWhenCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := OpenPostgresMigrationDatabaseWithContext(
		ctx,
		"postgres://localhost/test",
		time.Second,
	)
	if err != context.Canceled {
		t.Fatalf("error = %v, want context canceled", err)
	}
}

func TestOpenPostgresMigrationDatabaseRejectsInvalidInputBeforeConnecting(t *testing.T) {
	tests := []struct {
		name         string
		databaseURL  string
		pingTimeout  time.Duration
		wantContains string
	}{
		{
			name:         "missing URL",
			pingTimeout:  time.Second,
			wantContains: "database URL is required",
		},
		{
			name:         "missing timeout",
			databaseURL:  "postgres://localhost/test",
			wantContains: "ping timeout must be positive",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := OpenPostgresMigrationDatabaseWithContext(
				context.Background(),
				test.databaseURL,
				test.pingTimeout,
			)
			if err == nil || !strings.Contains(err.Error(), test.wantContains) {
				t.Fatalf("error = %v, want %q", err, test.wantContains)
			}
		})
	}
}
