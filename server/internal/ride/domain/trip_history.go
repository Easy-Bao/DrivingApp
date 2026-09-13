package domain

import "context"

type TripHistoryQuery struct {
	Limit      int
	Offset     int
	ActiveOnly bool
}

type RideHistoryReader interface {
	DriverTrips(ctx context.Context, driverID int, query TripHistoryQuery) ([]Ride, error)
	PassengerRides(ctx context.Context, passengerID int, query TripHistoryQuery) ([]Ride, error)
}

type RecentPassengerRidesReader interface {
	PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]Ride, error)
}

// TripHistoryRepository is the legacy name for RideHistoryReader.
//
// Deprecated: use RideHistoryReader instead.
type TripHistoryRepository = RideHistoryReader

// RecentPassengerRidesRepository is the legacy name for
// RecentPassengerRidesReader.
//
// Deprecated: use RecentPassengerRidesReader instead.
type RecentPassengerRidesRepository = RecentPassengerRidesReader
