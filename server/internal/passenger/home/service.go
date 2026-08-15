package home

import (
	"context"
	"errors"
	"strings"
)

const recentDestinationLimit = 25

var (
	ErrInvalidPassengerID = errors.New("passenger id is invalid")
	ErrInvalidCoordinates = errors.New("passenger home coordinates are invalid")
	ErrQueryUnavailable   = errors.New("passenger home query is unavailable")
)

type Service struct {
	recentDestinations RecentDestinationReader
	addressResolver    AddressResolver
}

func NewService(
	recentDestinations RecentDestinationReader,
	addressResolver AddressResolver,
) *Service {
	return &Service{
		recentDestinations: recentDestinations,
		addressResolver:    addressResolver,
	}
}

func (service *Service) Get(
	ctx context.Context,
	passengerID *int,
	coordinates *Coordinates,
) (Snapshot, error) {
	snapshot := Snapshot{
		RecentLocations: make([]RecentLocation, 0, 5),
	}

	if coordinates != nil {
		if !coordinates.Valid() {
			return Snapshot{}, ErrInvalidCoordinates
		}
		if service.addressResolver != nil {
			address, err := service.addressResolver.ResolveAddress(ctx, *coordinates)
			if err == nil {
				snapshot.CurrentAddress = strings.TrimSpace(address)
			}
		}
	}

	if passengerID == nil {
		return snapshot, nil
	}
	if *passengerID <= 0 {
		return Snapshot{}, ErrInvalidPassengerID
	}
	if service.recentDestinations == nil {
		return Snapshot{}, ErrQueryUnavailable
	}

	destinations, err := service.recentDestinations.ReadRecentDestinations(
		ctx,
		*passengerID,
		recentDestinationLimit,
	)
	if err != nil {
		return Snapshot{}, err
	}
	snapshot.RecentLocations = recentLocations(destinations)
	return snapshot, nil
}

func recentLocations(destinations []RecentDestination) []RecentLocation {
	locations := make([]RecentLocation, 0, 5)
	seenDestinations := make(map[string]struct{}, 5)
	for _, destination := range destinations {
		if strings.ToLower(strings.TrimSpace(destination.Status)) != "completed" {
			continue
		}
		title := strings.TrimSpace(destination.Title)
		if title == "" {
			continue
		}
		key := strings.ToLower(title)
		if _, seen := seenDestinations[key]; seen {
			continue
		}
		seenDestinations[key] = struct{}{}

		subtitle := strings.TrimSpace(destination.Subtitle)
		if subtitle == "" {
			subtitle = "Previous Trip"
		}
		locations = append(locations, RecentLocation{
			Title:     shortenAddress(title),
			Subtitle:  shortenAddress(subtitle),
			Latitude:  destination.Latitude,
			Longitude: destination.Longitude,
		})
		if len(locations) == 5 {
			break
		}
	}
	return locations
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
