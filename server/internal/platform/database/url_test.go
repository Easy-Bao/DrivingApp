package database

import (
	"fmt"
	"testing"
)

func TestNormalizePostgresURLPreservesExplicitTLSModes(t *testing.T) {
	for _, host := range []string{"localhost", "127.0.0.1", "postgres-db", "db.example.test"} {
		for _, mode := range []string{"require", "verify-ca", "verify-full", "prefer", "disable", ""} {
			t.Run(host+"/"+mode, func(t *testing.T) {
				input := fmt.Sprintf("postgres://user:pass@%s:5432/app?application_name=worker&sslmode=%s", host, mode)
				if got := NormalizePostgresURL(input); got != input {
					t.Fatalf("explicit TLS policy changed: got %q, want %q", got, input)
				}
			})
		}
	}
}

func TestNormalizePostgresURLDefaultsLocalConnectionsWithoutTLSMode(t *testing.T) {
	for _, host := range []string{"localhost", "127.0.0.1", "postgres-db"} {
		t.Run(host, func(t *testing.T) {
			input := fmt.Sprintf("postgres://user:pass@%s:5432/app?application_name=worker", host)
			want := input + "&sslmode=disable"
			if got := NormalizePostgresURL(input); got != want {
				t.Fatalf("local default = %q, want %q", got, want)
			}
		})
	}
}

func TestNormalizePostgresURLKeepsRemoteAndInvalidURLs(t *testing.T) {
	for _, input := range []string{"postgres://user:pass@db.example.test:5432/app", "postgres://user:pass@[invalid/app", "postgres://user:pass@localhost:5432/app?sslmode=verify-full&sslmode=require"} {
		if got := NormalizePostgresURL(input); got != input {
			t.Fatalf("URL changed: got %q, want %q", got, input)
		}
	}
}
