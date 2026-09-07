package postgres

import "testing"

func TestNewPostgresDashboardStatsRepositoryRejectsNilPool(t *testing.T) {
	if _, err := NewPostgresDashboardStatsRepository(nil); err == nil {
		t.Fatal("expected nil PostgreSQL pool to be rejected")
	}
}

func TestPostgresCountToIntRejectsNegativeValues(t *testing.T) {
	if _, err := postgresCountToInt(-1); err == nil {
		t.Fatal("expected negative count to be rejected")
	}
}

func TestPostgresCountToIntMapsValidValues(t *testing.T) {
	value, err := postgresCountToInt(42)
	if err != nil {
		t.Fatalf("postgresCountToInt() error = %v", err)
	}
	if value != 42 {
		t.Fatalf("postgresCountToInt() = %d, want 42", value)
	}
}
