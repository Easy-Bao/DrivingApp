//go:build integration

package ride_test

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

type analyticsRepository struct{}

func (analyticsRepository) CreateRide(context.Context, domain.Ride) (domain.Ride, error) {
	return domain.Ride{}, nil
}

func (analyticsRepository) Get(context.Context, int) (domain.Ride, error) {
	return domain.Ride{}, nil
}

func (analyticsRepository) DriverStats(context.Context, int, time.Time, time.Time) (domain.DriverStats, error) {
	return domain.DriverStats{
		DriverID:            7,
		TotalTrips:          3,
		CompletedTrips:      2,
		TodayCompletedTrips: 1,
		TodayEarnings:       2817,
	}, nil
}

func (analyticsRepository) DriverEarnings(context.Context, int, time.Time, time.Time) ([]domain.DriverEarning, error) {
	return []domain.DriverEarning{{CompletedAt: time.Now(), PayoutAmount: 2817}}, nil
}

func (analyticsRepository) DriverTrips(context.Context, int, domain.TripHistoryQuery) ([]domain.Ride, error) {
	return []domain.Ride{{ID: 3}}, nil
}

func (analyticsRepository) PassengerRides(context.Context, int, domain.TripHistoryQuery) ([]domain.Ride, error) {
	return []domain.Ride{{ID: 2}}, nil
}

func (analyticsRepository) PassengerActivitySummary(
	context.Context,
	int,
	time.Time,
	time.Time,
) (domain.PassengerActivitySummary, error) {
	return domain.PassengerActivitySummary{ThisWeekFareAmount: 2817, ThisWeekCompletedRides: 1}, nil
}
