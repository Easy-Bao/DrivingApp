package app

import (
	"context"
	"errors"
	"fmt"
	"strings"

	locationapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/app"
	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/domain"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

type locationResolver struct {
	service *locationapplication.Service
}

var _ rideapplication.AddressResolver = (*locationResolver)(nil)

func newLocationResolver(service *locationapplication.Service) *locationResolver {
	return &locationResolver{service: service}
}

func (resolver *locationResolver) ResolveAddress(
	ctx context.Context,
	coordinates ridedomain.Coordinates,
) (string, error) {
	if resolver.service == nil {
		return "", errors.New("location module is unavailable")
	}
	place, err := resolver.service.ReverseGeocode(ctx, locationdomain.Coordinates{
		Latitude:  coordinates.Latitude,
		Longitude: coordinates.Longitude,
	})
	if err != nil {
		return "", fmt.Errorf("reverse geocode ride context address: %w", err)
	}
	return formatPlaceAddress(place), nil
}

func formatPlaceAddress(place *locationdomain.Place) string {
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
	if name := strings.TrimSpace(place.Name); name != "" {
		return name
	}
	return shortenPlaceAddress(place.Address)
}

func shortenPlaceAddress(address string) string {
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
