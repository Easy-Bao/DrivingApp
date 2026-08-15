package adapter

import (
	"context"
	"errors"

	home "github.com/Easy-Bao/DrivingApp/server/internal/passenger/home"
	ridesusecase "github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
)

type RidesReader struct {
	service *ridesusecase.Service
}

func NewRidesReader(service *ridesusecase.Service) *RidesReader {
	return &RidesReader{service: service}
}

func (reader *RidesReader) ReadRecentDestinations(
	ctx context.Context,
	passengerID, limit int,
) ([]home.RecentDestination, error) {
	if reader.service == nil {
		return nil, errors.New("rides module is unavailable")
	}
	rides, err := reader.service.PassengerRecentRides(ctx, passengerID, limit)
	if err != nil {
		return nil, err
	}

	destinations := make([]home.RecentDestination, 0, len(rides))
	for _, ride := range rides {
		destinations = append(destinations, home.RecentDestination{
			Status:    ride.Status,
			Title:     ride.DropoffName,
			Subtitle:  ride.PickupName,
			Latitude:  ride.DropoffLatitude,
			Longitude: ride.DropoffLongitude,
		})
	}
	return destinations, nil
}
