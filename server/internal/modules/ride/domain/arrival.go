package domain

import "math"

const _earthRadiusMeters = 6_371_000.0

func ValidateArrivalLocation(
	pickupLatitude,
	pickupLongitude,
	driverLatitude,
	driverLongitude,
	radiusMeters float64,
) error {
	pickupValid := Coordinates{Latitude: pickupLatitude, Longitude: pickupLongitude}.Valid()
	driverValid := Coordinates{Latitude: driverLatitude, Longitude: driverLongitude}.Valid()
	if !pickupValid || !driverValid || !validRadius(radiusMeters) {
		return ErrArrivalLocation
	}
	if haversineMeters(
		pickupLatitude,
		pickupLongitude,
		driverLatitude,
		driverLongitude,
	) > radiusMeters {
		return ErrArrivalLocation
	}
	return nil
}

func validRadius(radiusMeters float64) bool {
	return radiusMeters > 0 && !math.IsNaN(radiusMeters) && !math.IsInf(radiusMeters, 0)
}

func haversineMeters(
	firstLatitude,
	firstLongitude,
	secondLatitude,
	secondLongitude float64,
) float64 {
	latitudeDelta := (secondLatitude - firstLatitude) * math.Pi / 180
	longitudeDelta := (secondLongitude - firstLongitude) * math.Pi / 180
	firstLatitudeRadians := firstLatitude * math.Pi / 180
	secondLatitudeRadians := secondLatitude * math.Pi / 180
	a := math.Sin(latitudeDelta/2)*math.Sin(latitudeDelta/2) +
		math.Cos(firstLatitudeRadians)*math.Cos(secondLatitudeRadians)*
			math.Sin(longitudeDelta/2)*math.Sin(longitudeDelta/2)
	a = min(1, max(0, a))
	return 2 * _earthRadiusMeters * math.Asin(math.Sqrt(a))
}
