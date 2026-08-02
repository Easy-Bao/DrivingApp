package tests

import (
	"os"
	"strconv"
	"testing"
)

func mapboxAccessToken(t *testing.T) string {
	t.Helper()
	if os.Getenv("LOCATION_SERVICE_INTEGRATION") != "true" {
		t.Skip("set LOCATION_SERVICE_INTEGRATION=true for Mapbox integration tests")
	}
	token := os.Getenv("MAPBOX_ACCESS_TOKEN")
	if token == "" {
		token = os.Getenv("MAPBOX_PUBLIC_TOKEN")
	}
	if token == "" {
		t.Skip("MAPBOX_ACCESS_TOKEN or MAPBOX_PUBLIC_TOKEN is required")
	}
	return token
}

func parseCoordinate(t *testing.T, value string) float64 {
	t.Helper()
	coordinate, err := strconv.ParseFloat(value, 64)
	if err != nil {
		t.Fatalf("invalid test coordinate %q: %v", value, err)
	}
	return coordinate
}

func locationTestCoordinates(t *testing.T) (float64, float64) {
	t.Helper()
	lat, ok := os.LookupEnv("LOCATION_TEST_LAT")
	if !ok || lat == "" {
		t.Skip("LOCATION_TEST_LAT is required for database-backed location tests")
	}
	lng, ok := os.LookupEnv("LOCATION_TEST_LNG")
	if !ok || lng == "" {
		t.Skip("LOCATION_TEST_LNG is required for database-backed location tests")
	}
	return parseCoordinate(t, lat), parseCoordinate(t, lng)
}
