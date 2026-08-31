package adapter

import (
	"context"
	"errors"

	ridecontext "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context"
	ridesapplication "github.com/Easy-Bao/DrivingApp/server/internal/rides/application"
)

type RidesReader struct {
	service *ridesapplication.RideService
}

func NewRidesReader(service *ridesapplication.RideService) *RidesReader {
	return &RidesReader{service: service}
}

func (reader *RidesReader) ReadRecentDestinations(
	ctx context.Context,
	passengerID, limit int,
) ([]ridecontext.RecentDestination, error) {
	if reader.service == nil {
		return nil, errors.New("rides module is unavailable")
	}
	rides, err := reader.service.PassengerRecentRides(ctx, passengerID, limit)
	if err != nil {
		return nil, err
	}

	destinations := make([]ridecontext.RecentDestination, 0, len(rides))
	for _, ride := range rides {
		destinations = append(destinations, ridecontext.RecentDestination{
			Status:    ride.Status,
			Title:     ride.DropoffName,
			Subtitle:  ride.PickupName,
			Latitude:  ride.DropoffLatitude,
			Longitude: ride.DropoffLongitude,
		})
	}
	return destinations, nil
}
