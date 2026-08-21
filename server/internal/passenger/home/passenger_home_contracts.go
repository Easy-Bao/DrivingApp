package home

import (
	"context"
	"math"
)

type Coordinates struct {
	Latitude  float64
	Longitude float64
}

func (coordinates Coordinates) Valid() bool {
	return !math.IsNaN(coordinates.Latitude) &&
		!math.IsInf(coordinates.Latitude, 0) &&
		!math.IsNaN(coordinates.Longitude) &&
		!math.IsInf(coordinates.Longitude, 0) &&
		coordinates.Latitude >= -90 && coordinates.Latitude <= 90 &&
		coordinates.Longitude >= -180 && coordinates.Longitude <= 180
}

type RecentDestination struct {
	Status    string
	Title     string
	Subtitle  string
	Latitude  float64
	Longitude float64
}

type RecentLocation struct {
	Title     string
	Subtitle  string
	Latitude  float64
	Longitude float64
}

type Snapshot struct {
	CurrentAddress  string
	RecentLocations []RecentLocation
}

type RecentDestinationReader interface {
	ReadRecentDestinations(ctx context.Context, passengerID, limit int) ([]RecentDestination, error)
}

type AddressResolver interface {
	ResolveAddress(ctx context.Context, coordinates Coordinates) (string, error)
}

type Query interface {
	Get(ctx context.Context, passengerID *int, coordinates *Coordinates) (Snapshot, error)
}
