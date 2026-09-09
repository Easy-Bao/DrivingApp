package domain

import "context"

type TripHistoryQuery struct {
	Limit      int
	Offset     int
	ActiveOnly bool
}

// RideHistoryReader exposes read-only trip history projections.
type RideHistoryReader interface {
	DriverTrips(ctx context.Context, driverID int, query TripHistoryQuery) ([]Ride, error)
	PassengerRides(ctx context.Context, passengerID int, query TripHistoryQuery) ([]Ride, error)
}

// RecentPassengerRidesReader exposes the bounded recent-rides projection.
type RecentPassengerRidesReader interface {
	PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]Ride, error)
}

// TripHistoryRepository preserves the legacy port name for existing callers.
type TripHistoryRepository = RideHistoryReader

// RecentPassengerRidesRepository preserves the legacy port name for existing callers.
type RecentPassengerRidesRepository = RecentPassengerRidesReader
