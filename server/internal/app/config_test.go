package app

import (
	"testing"
	"time"

	ridelifecycle "github.com/Easy-Bao/DrivingApp/server/internal/ride/lifecycle"
)

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

func TestRideLifecycleConfigUsesDefaultPassengerWait(t *testing.T) {
	config, err := loadRideLifecycleConfig(func(string) string { return "" })
	if err != nil {
		t.Fatalf("loadRideLifecycleConfig() error = %v", err)
	}
	if config.PassengerWaitDuration != ridelifecycle.DefaultPassengerWaitDuration {
		t.Fatalf("passenger wait = %v, want %v", config.PassengerWaitDuration, ridelifecycle.DefaultPassengerWaitDuration)
	}
	if config.ArrivalRadiusMeters != ridelifecycle.DefaultArrivalRadiusMeters ||
		config.CompletionRadiusMeters != ridelifecycle.DefaultCompletionRadiusMeters {
		t.Fatalf("ride radii = arrival %v, completion %v", config.ArrivalRadiusMeters, config.CompletionRadiusMeters)
	}
}

func TestRideLifecycleConfigAcceptsSeparateLocationRadii(t *testing.T) {
	values := map[string]string{
		"RIDE_ARRIVAL_RADIUS_METERS":    "175.5",
		"RIDE_COMPLETION_RADIUS_METERS": "325",
	}
	config, err := loadRideLifecycleConfig(func(key string) string { return values[key] })
	if err != nil {
		t.Fatalf("loadRideLifecycleConfig() error = %v", err)
	}
	if config.ArrivalRadiusMeters != 175.5 || config.CompletionRadiusMeters != 325 {
		t.Fatalf("ride radii = arrival %v, completion %v", config.ArrivalRadiusMeters, config.CompletionRadiusMeters)
	}
}

func TestRideLifecycleConfigAcceptsWholeSecondDuration(t *testing.T) {
	config, err := loadRideLifecycleConfig(func(key string) string {
		if key == "PASSENGER_NO_SHOW_WAIT" {
			return "7m30s"
		}
		return ""
	})
	if err != nil {
		t.Fatalf("loadRideLifecycleConfig() error = %v", err)
	}
	if config.PassengerWaitDuration != 7*time.Minute+30*time.Second {
		t.Fatalf("passenger wait = %v", config.PassengerWaitDuration)
	}
}

func TestRideLifecycleConfigRejectsInvalidLocationRadii(t *testing.T) {
	for _, value := range []string{"invalid", "0", "-1", "NaN", "+Inf"} {
		t.Run(value, func(t *testing.T) {
			_, err := loadRideLifecycleConfig(func(key string) string {
				if key == "RIDE_ARRIVAL_RADIUS_METERS" {
					return value
				}
				return ""
			})
			if err == nil {
				t.Fatalf("RIDE_ARRIVAL_RADIUS_METERS=%q should be rejected", value)
			}
		})
	}
}

func TestRideLifecycleConfigRejectsUnsafeDurations(t *testing.T) {
	for _, value := range []string{"invalid", "0s", "-1m", "500ms"} {
		t.Run(value, func(t *testing.T) {
			_, err := loadRideLifecycleConfig(func(string) string { return value })
			if err == nil {
				t.Fatalf("PASSENGER_NO_SHOW_WAIT=%q should be rejected", value)
			}
		})
	}
}
