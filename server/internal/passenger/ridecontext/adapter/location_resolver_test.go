package adapter

import (
	"testing"

	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

func TestFormatAddressFallsBackToPlaceName(t *testing.T) {
	place := &locationdomain.Place{Name: "Mountain View"}

	if got := formatAddress(place); got != "Mountain View" {
		t.Fatalf("formatted address = %q, want Mountain View", got)
	}
}
