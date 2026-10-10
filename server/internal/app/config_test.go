package app

import "testing"

func TestAPIAddressDefaultsToLoopback(t *testing.T) {
	if got, want := apiAddress("", "8000"), "127.0.0.1:8000"; got != want {
		t.Fatalf("apiAddress() = %q, want %q", got, want)
	}
}

func TestAPIAddressUsesExplicitContainerHost(t *testing.T) {
	if got, want := apiAddress("0.0.0.0", "8000"), "0.0.0.0:8000"; got != want {
		t.Fatalf("apiAddress() = %q, want %q", got, want)
	}
}
