package geo

import (
	"math"
	"testing"
)

func TestValidCoordinates(t *testing.T) {
	validCases := [][2]float64{
		{0, 0},
		{-90, -180},
		{90, 180},
		{14.5995, 120.9842},
	}
	for _, coords := range validCases {
		if !ValidCoordinates(coords[0], coords[1]) {
			t.Fatalf("expected valid coordinates (%v, %v)", coords[0], coords[1])
		}
	}

	invalidCases := [][2]float64{
		{math.NaN(), 0},
		{0, math.NaN()},
		{math.Inf(1), 0},
		{0, math.Inf(-1)},
		{-90.001, 0},
		{90.001, 0},
		{0, -180.001},
		{0, 180.001},
	}
	for _, coords := range invalidCases {
		if ValidCoordinates(coords[0], coords[1]) {
			t.Fatalf("expected invalid coordinates (%v, %v)", coords[0], coords[1])
		}
	}
}

func TestDistanceKmAndMeters(t *testing.T) {
	if got := DistanceMeters(14.5995, 120.9842, 14.5995, 120.9842); got != 0 {
		t.Fatalf("identical point distance = %v, want 0", got)
	}
	km := DistanceKm(0, 0, 0, 1)
	meters := DistanceMeters(0, 0, 0, 1)
	if math.Abs(km-111.1949) > 0.01 {
		t.Fatalf("DistanceKm(0,0 -> 0,1) = %v, want ~111.19", km)
	}
	if math.Abs(meters-km*1000) > 1e-6 {
		t.Fatalf("DistanceMeters = %v, DistanceKm*1000 = %v", meters, km*1000)
	}
}
