package database

import "testing"

func TestNormalizePostgresURLDisablesTLSForLocalHosts(t *testing.T) {
	value := NormalizePostgresURL("postgres://user:pass@localhost:5432/app?sslmode=require")
	if value != "postgres://user:pass@localhost:5432/app?sslmode=disable" {
		t.Fatalf("normalized local URL = %q", value)
	}
}

func TestNormalizePostgresURLKeepsRemoteTLSConfiguration(t *testing.T) {
	value := NormalizePostgresURL("postgres://user:pass@db.example.test:5432/app?sslmode=require")
	if value != "postgres://user:pass@db.example.test:5432/app?sslmode=require" {
		t.Fatalf("normalized remote URL = %q", value)
	}
}
