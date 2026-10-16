package app_test

import (
	"context"
	"testing"
	"time"

	rideconfig "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/adapter/config"
	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

type analyticsRepository struct{}

type mutableAnalyticsRepository struct {
	analyticsRepository
	rides []domain.Ride
}

func newAnalyticsRideService(repository application.RideStore, config application.PricingConfig) *application.RideService {
	return application.NewRideService(application.RideServiceDependencies{
		Repository:    repository,
		PricingConfig: config,
	})
}

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
func (repository *mutableAnalyticsRepository) PassengerRides(
	context.Context,
	int,
	domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	return repository.rides, nil
}

func TestAnalyticsUseCasesDelegateToTheRideAdapter(t *testing.T) {
	config, err := rideconfig.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	service := newAnalyticsRideService(analyticsRepository{}, config)

	stats, err := service.DriverStats(context.Background(), 7)
	if err != nil || stats.TotalTrips != 3 {
		t.Fatalf("driver stats = %#v, %v", stats, err)
	}
	trips, err := service.PassengerRides(context.Background(), 8, domain.TripHistoryQuery{Limit: 25})
	if err != nil || len(trips) != 1 || trips[0].ID != 2 {
		t.Fatalf("passenger rides = %#v, %v", trips, err)
	}
}

func TestRideHistoryReadsReturnCopiesAtTheApplicationBoundary(t *testing.T) {
	config, err := rideconfig.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	repository := &mutableAnalyticsRepository{rides: []domain.Ride{{ID: 2}}}
	service := newAnalyticsRideService(repository, config)

	rides, err := service.PassengerRides(context.Background(), 8, domain.TripHistoryQuery{Limit: 25})
	if err != nil {
		t.Fatalf("PassengerRides() error = %v", err)
	}
	rides[0].ID = 99
	if repository.rides[0].ID != 2 {
		t.Fatalf("repository rides were mutated through returned values: %#v", repository.rides)
	}

}
