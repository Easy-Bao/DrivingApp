package ridecontext

import (
	ridecontextapplication "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext/application"
	ridecontextdomain "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext/domain"
	ridecontextports "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext/ports"
)

type Coordinates = ridecontextdomain.Coordinates
type RecentDestination = ridecontextdomain.RecentDestination
type RecentLocation = ridecontextdomain.RecentLocation
type RideContextSnapshot = ridecontextdomain.RideContextSnapshot
type RecentDestinationReader = ridecontextports.RecentDestinationReader
type AddressResolver = ridecontextports.AddressResolver
type RideContextQuery = ridecontextports.Query
type RideContextQueryService = ridecontextapplication.RideContextQueryService

var (
	ErrInvalidPassengerID = ridecontextapplication.ErrInvalidPassengerID
	ErrInvalidCoordinates = ridecontextapplication.ErrInvalidCoordinates
	ErrQueryUnavailable   = ridecontextapplication.ErrQueryUnavailable
)

func NewRideContextQueryService(
	recentDestinations RecentDestinationReader,
	addressResolver AddressResolver,
) *RideContextQueryService {
	return ridecontextapplication.NewQueryService(recentDestinations, addressResolver)
}
