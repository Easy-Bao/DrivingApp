package geo

import "math"

const (
	// EarthRadiusKm is the mean Earth radius in kilometers used for haversine distances.
	EarthRadiusKm = 6371.0
	// EarthRadiusMeters is the mean Earth radius in meters used for haversine distances.
	EarthRadiusMeters = 6_371_000.0
	_degreesToRadians = math.Pi / 180
)

// ValidCoordinates reports whether latitude and longitude are finite decimal degree coordinates.
func ValidCoordinates(latitude, longitude float64) bool {
	return isFiniteInRange(latitude, -90, 90) &&
		isFiniteInRange(longitude, -180, 180)
}

// DistanceKm computes the great-circle haversine distance in kilometers between two coordinates.
func DistanceKm(latitude1, longitude1, latitude2, longitude2 float64) float64 {
	return EarthRadiusKm * centralAngleRadians(latitude1, longitude1, latitude2, longitude2)
}

// DistanceMeters computes the great-circle haversine distance in meters between two coordinates.
func DistanceMeters(latitude1, longitude1, latitude2, longitude2 float64) float64 {
	return EarthRadiusMeters * centralAngleRadians(latitude1, longitude1, latitude2, longitude2)
}

func centralAngleRadians(latitude1, longitude1, latitude2, longitude2 float64) float64 {
	deltaLatitude := (latitude2 - latitude1) * _degreesToRadians
	deltaLongitude := (longitude2 - longitude1) * _degreesToRadians
	lat1Rad := latitude1 * _degreesToRadians
	lat2Rad := latitude2 * _degreesToRadians
	a := math.Sin(deltaLatitude/2)*math.Sin(deltaLatitude/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*math.Sin(deltaLongitude/2)*math.Sin(deltaLongitude/2)
	a = min(1, max(0, a))
	return 2 * math.Asin(math.Sqrt(a))
}

func isFiniteInRange(value, minimum, maximum float64) bool {
	return !math.IsNaN(value) &&
		!math.IsInf(value, 0) &&
		value >= minimum &&
		value <= maximum
}
