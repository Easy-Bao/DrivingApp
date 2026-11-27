package app

import (
	"testing"

	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/domain"
)

func TestFormatPlaceAddressFallsBackToPlaceName(t *testing.T) {
	place := &locationdomain.Place{Name: "Mountain View"}

	if got := formatPlaceAddress(place); got != "Mountain View" {
		t.Fatalf("formatted address = %q, want Mountain View", got)
	}
}
