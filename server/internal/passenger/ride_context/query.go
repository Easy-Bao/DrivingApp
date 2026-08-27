package ridecontext

import (
	"context"
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	recentDestinationLimit = 25
	currentAddressTimeout  = 750 * time.Millisecond
)

var (
	ErrInvalidPassengerID = errors.New("passenger id is invalid")
	ErrInvalidCoordinates = errors.New("passenger ridecontext coordinates are invalid")
	ErrQueryUnavailable   = errors.New("passenger ridecontext query is unavailable")
)

type RideContextQueryService struct {
	recentDestinations RecentDestinationReader
	addressResolver    AddressResolver
}

func NewRideContextQueryService(
	recentDestinations RecentDestinationReader,
	addressResolver AddressResolver,
) *RideContextQueryService {
	return &RideContextQueryService{
		recentDestinations: recentDestinations,
		addressResolver:    addressResolver,
	}
}

func (service *RideContextQueryService) Load(
	ctx context.Context,
	passengerID *int,
	coordinates *Coordinates,
) (RideContextSnapshot, error) {
	snapshot := RideContextSnapshot{
		RecentLocations: make([]RecentLocation, 0, 5),
	}

	if coordinates != nil {
		if !coordinates.Valid() {
			return RideContextSnapshot{}, ErrInvalidCoordinates
		}
	}

	if passengerID == nil {
		if coordinates != nil && service.addressResolver != nil {
			address, err := resolveAddress(ctx, service.addressResolver, *coordinates)
			if err == nil {
				snapshot.CurrentAddress = strings.TrimSpace(address)
			}
		}
		return snapshot, nil
	}
	if *passengerID <= 0 {
		return RideContextSnapshot{}, ErrInvalidPassengerID
	}
	if service.recentDestinations == nil {
		return RideContextSnapshot{}, ErrQueryUnavailable
	}

	var (
		address      string
		addressError error
		waitGroup    sync.WaitGroup
	)
	if coordinates != nil && service.addressResolver != nil {
		waitGroup.Go(func() {
			address, addressError = resolveAddress(ctx, service.addressResolver, *coordinates)
		})
	}

	destinations, err := service.recentDestinations.ReadRecentDestinations(
		ctx,
		*passengerID,
		recentDestinationLimit,
	)
	waitGroup.Wait()
	if err != nil {
		return RideContextSnapshot{}, err
	}
	if addressError == nil {
		snapshot.CurrentAddress = strings.TrimSpace(address)
	}
	snapshot.RecentLocations = recentLocations(destinations)
	return snapshot, nil
}

func resolveAddress(
	ctx context.Context,
	resolver AddressResolver,
	coordinates Coordinates,
) (string, error) {
	addressContext, cancel := context.WithTimeout(ctx, currentAddressTimeout)
	defer cancel()
	return resolver.ResolveAddress(addressContext, coordinates)
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
