package postgres

import "testing"

func TestNewStatsRepositoryRejectsNilPool(t *testing.T) {
	if _, err := NewStatsRepository(nil); err == nil {
		t.Fatal("expected nil PostgreSQL pool to be rejected")
	}
}

func TestCountToIntRejectsNegativeValues(t *testing.T) {
	if _, err := countToInt(-1); err == nil {
		t.Fatal("expected negative count to be rejected")
	}
}

func TestCountToIntMapsValidValues(t *testing.T) {
	value, err := countToInt(42)
	if err != nil {
		t.Fatalf("countToInt() error = %v", err)
	}
	if value != 42 {
		t.Fatalf("countToInt() = %d, want 42", value)
	}
}
