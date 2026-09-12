package adapter

import (
	"context"
	"errors"
	"fmt"

	ridecontextdomain "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext/domain"
	ridecontextports "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext/ports"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
)

type RidesReader struct {
	service *rideapplication.RideService
}

var _ ridecontextports.RecentDestinationReader = (*RidesReader)(nil)

func NewRidesReader(service *rideapplication.RideService) *RidesReader {
	return &RidesReader{service: service}
}

func (reader *RidesReader) ReadRecentDestinations(
	ctx context.Context,
	passengerID, limit int,
) ([]ridecontextdomain.RecentDestination, error) {
	if reader.service == nil {
		return nil, errors.New("rides module is unavailable")
	}
	rides, err := reader.service.PassengerRecentRides(ctx, passengerID, limit)
	if err != nil {
		return nil, fmt.Errorf("load recent passenger rides: %w", err)
	}

	destinations := make([]ridecontextdomain.RecentDestination, 0, len(rides))
	for _, ride := range rides {
		destinations = append(destinations, ridecontextdomain.RecentDestination{
			Status:    ride.Status,
			Title:     ride.DropoffName,
			Subtitle:  ride.PickupName,
			Latitude:  ride.DropoffLatitude,
			Longitude: ride.DropoffLongitude,
		})
	}
	return destinations, nil
}
