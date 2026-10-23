package domain

import (
	"context"
	"time"
)

type TripHistoryQuery struct {
	Limit           int
	Offset          int
	ActiveOnly      bool
	BeforeCreatedAt time.Time
	BeforeID        int
}

type RideHistoryReader interface {
	DriverTrips(ctx context.Context, driverID int, query TripHistoryQuery) ([]Ride, error)
	PassengerRides(ctx context.Context, passengerID int, query TripHistoryQuery) ([]Ride, error)
}

type RecentPassengerRidesReader interface {
	PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]Ride, error)
}
