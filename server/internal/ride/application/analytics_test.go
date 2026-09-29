package application_test

import (
	"context"
	"testing"
	"time"

	rideconfig "github.com/Easy-Bao/DrivingApp/server/internal/ride/adapter/config"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

type analyticsRepository struct{}

type passengerReviewRepository struct{ analyticsRepository }

type mutableAnalyticsRepository struct {
	analyticsRepository
	rides   []domain.Ride
	drivers []domain.OnlineDriver
}

func newAnalyticsRideService(repository ports.RideStore, config application.PricingConfig) *application.RideService {
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
func (analyticsRepository) DriverReviews(context.Context, int, int, int) ([]domain.Review, error) {
	return []domain.Review{{Rating: 5}}, nil
}
func (analyticsRepository) CreateReview(_ context.Context, review domain.Review) (domain.Review, error) {
	review.ID = 1
	return review, nil
}
func (analyticsRepository) OnlineDrivers(context.Context, []int) ([]domain.OnlineDriver, error) {
	return []domain.OnlineDriver{{
		ID:                    7,
		UserID:                7,
		Name:                  "Ada Driver",
		VehicleType:           "Motorcycle",
		PlateNumber:           "XYZ-123",
		Rating:                4.8,
		OnboardPassengerCount: 1,
	}}, nil
}
func (analyticsRepository) PublicDriverSummaries(context.Context, int) ([]domain.PublicDriverSummary, error) {
	return []domain.PublicDriverSummary{{
		ID: 7, Name: "Ada Driver", VehicleType: "Motorcycle", Rating: 4.8,
	}}, nil
}
func (passengerReviewRepository) CreatePassengerReview(
	_ context.Context,
	review domain.PassengerReview,
) (domain.PassengerReview, error) {
	review.ID = 1
	return review, nil
}

func (repository *mutableAnalyticsRepository) PassengerRides(
	context.Context,
	int,
	domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	return repository.rides, nil
}

func (repository *mutableAnalyticsRepository) OnlineDrivers(
	context.Context,
	[]int,
) ([]domain.OnlineDriver, error) {
	return repository.drivers, nil
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
	review, err := service.CreateReview(context.Background(), domain.Review{DriverID: 7, Rating: 5})
	if err != nil || review.ID != 1 {
		t.Fatalf("review = %#v, %v", review, err)
	}
	if _, err := service.CreateReview(context.Background(), domain.Review{DriverID: 7, Rating: 6}); err == nil {
		t.Fatal("expected out-of-range rating to be rejected")
	}
}

func TestPassengerReviewUseCaseValidatesRatingAndDelegates(t *testing.T) {
	config, err := rideconfig.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	service := newAnalyticsRideService(passengerReviewRepository{}, config)
	review, err := service.CreatePassengerReview(context.Background(), domain.PassengerReview{RideID: 9, Rating: 5})
	if err != nil || review.ID != 1 {
		t.Fatalf("passenger review = %#v, %v", review, err)
	}
	_, err = service.CreatePassengerReview(
		context.Background(),
		domain.PassengerReview{RideID: 9, Rating: 0},
	)
	if err == nil {
		t.Fatal("expected out-of-range passenger rating to be rejected")
	}
}

func TestAnalyticsReadsReturnCopiesAtTheApplicationBoundary(t *testing.T) {
	config, err := rideconfig.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	repository := &mutableAnalyticsRepository{
		rides:   []domain.Ride{{ID: 2}},
		drivers: []domain.OnlineDriver{{ID: 7}},
	}
	service := newAnalyticsRideService(repository, config)

	rides, err := service.PassengerRides(context.Background(), 8, domain.TripHistoryQuery{Limit: 25})
	if err != nil {
		t.Fatalf("PassengerRides() error = %v", err)
	}
	rides[0].ID = 99
	if repository.rides[0].ID != 2 {
		t.Fatalf("repository rides were mutated through returned values: %#v", repository.rides)
	}

	drivers, err := service.OnlineDrivers(context.Background(), []int{7})
	if err != nil {
		t.Fatalf("OnlineDrivers() error = %v", err)
	}
	drivers[0].ID = 99
	if repository.drivers[0].ID != 7 {
		t.Fatalf("repository drivers were mutated through returned values: %#v", repository.drivers)
	}
}
