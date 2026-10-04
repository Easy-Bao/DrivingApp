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
	if !validCoordinate(pickupLatitude, pickupLongitude) ||
		!validCoordinate(driverLatitude, driverLongitude) ||
		!validRadius(radiusMeters) {
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

func ValidateCompletionLocation(
	dropoffLatitude,
	dropoffLongitude,
	driverLatitude,
	driverLongitude,
	radiusMeters float64,
) error {
	if !validCoordinate(dropoffLatitude, dropoffLongitude) ||
		!validCoordinate(driverLatitude, driverLongitude) ||
		!validRadius(radiusMeters) {
		return ErrCompletionLocation
	}
	if haversineMeters(
		dropoffLatitude,
		dropoffLongitude,
		driverLatitude,
		driverLongitude,
	) > radiusMeters {
		return ErrCompletionLocation
	}
	return nil
}

func validRadius(radiusMeters float64) bool {
	return radiusMeters > 0 && !math.IsNaN(radiusMeters) && !math.IsInf(radiusMeters, 0)
}

func validCoordinate(latitude, longitude float64) bool {
	return !math.IsNaN(latitude) && !math.IsInf(latitude, 0) &&
		!math.IsNaN(longitude) && !math.IsInf(longitude, 0) &&
		latitude >= -90 && latitude <= 90 &&
		longitude >= -180 && longitude <= 180
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
	return 2 * _earthRadiusMeters * math.Asin(math.Sqrt(a))
}
