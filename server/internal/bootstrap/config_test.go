package bootstrap

import "testing"

func TestAPIAddressDefaultsToLoopback(t *testing.T) {
	t.Setenv("API_HOST", "")
	t.Setenv("API_PORT", "8000")
	port, err := requiredPortEnv("API_PORT")
	if err != nil {
		t.Fatalf("read API_PORT: %v", err)
	}

	if got, want := apiAddress(apiHost(), port), "127.0.0.1:8000"; got != want {
		t.Fatalf("api address = %q, want %q", got, want)
	}
}

func TestAPIAddressUsesExplicitContainerHost(t *testing.T) {
	t.Setenv("API_HOST", "0.0.0.0")
	t.Setenv("API_PORT", "9000")
	port, err := requiredPortEnv("API_PORT")
	if err != nil {
		t.Fatalf("read API_PORT: %v", err)
	}

	if got, want := apiAddress(apiHost(), port), "0.0.0.0:9000"; got != want {
		t.Fatalf("api address = %q, want %q", got, want)
	}
}

func TestRequiredPortEnvRejectsMissingOrInvalidValues(t *testing.T) {
	for _, value := range []string{"", "0", "65536", "not-a-port"} {
		t.Setenv("API_PORT", value)
		if _, err := requiredPortEnv("API_PORT"); err == nil {
			t.Fatalf("API_PORT=%q should be rejected", value)
		}
	}
}
