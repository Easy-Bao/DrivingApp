package adapter

import (
	"context"
	"errors"
	"strings"

	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	locationusecase "github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	home "github.com/Easy-Bao/DrivingApp/server/internal/passenger/home"
)

type LocationResolver struct {
	service *locationusecase.Service
}

func NewLocationResolver(service *locationusecase.Service) *LocationResolver {
	return &LocationResolver{service: service}
}

func (resolver *LocationResolver) ResolveAddress(
	ctx context.Context,
	coordinates home.Coordinates,
) (string, error) {
	if resolver.service == nil {
		return "", errors.New("location module is unavailable")
	}
	place, err := resolver.service.ReverseGeocode(ctx, locationdomain.Coordinates{
		Latitude:  coordinates.Latitude,
		Longitude: coordinates.Longitude,
	})
	if err != nil {
		return "", err
	}
	return formatAddress(place), nil
}

func formatAddress(place *locationdomain.Place) string {
	if place == nil {
		return ""
	}
	for _, key := range []string{
		"place",
		"locality",
		"municipality",
		"district",
		"county",
		"region",
	} {
		if value := strings.TrimSpace(place.Context[key]); value != "" {
			return value
		}
	}
	return shortenAddress(place.Address)
}

func shortenAddress(address string) string {
	address = strings.TrimSpace(address)
	parts := strings.Split(address, ",")
	for index := range parts {
		parts[index] = strings.TrimSpace(parts[index])
	}
	if len(parts) >= 2 {
		return parts[len(parts)-2] + ", " + parts[len(parts)-1]
	}
	return address
}
