package domain

import (
	"math"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/geo"
)

func ValidateArrivalLocation(
	pickupLatitude,
	pickupLongitude,
	driverLatitude,
	driverLongitude,
	radiusMeters float64,
) error {
	if !geo.ValidCoordinates(pickupLatitude, pickupLongitude) ||
		!geo.ValidCoordinates(driverLatitude, driverLongitude) ||
		!validRadius(radiusMeters) {
		return ErrArrivalLocation
	}
	if geo.DistanceMeters(
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
