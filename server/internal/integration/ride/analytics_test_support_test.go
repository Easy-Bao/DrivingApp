//go:build integration

package ride_test

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

type analyticsRepository struct{}

type passengerReviewRepository struct{ analyticsRepository }

func (analyticsRepository) CreateRide(context.Context, domain.Ride) (domain.Ride, error) {
	return domain.Ride{}, nil
}

func (analyticsRepository) CreateBid(context.Context, domain.Bid) (domain.Bid, error) {
	return domain.Bid{}, nil
}

func (analyticsRepository) AcceptBid(context.Context, int, int) (domain.Bid, domain.Ride, error) {
	return domain.Bid{}, domain.Ride{}, nil
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
	return []domain.DriverEarning{{CompletedAt: time.Now(), PayoutCentavos: 2817}}, nil
}

func (analyticsRepository) DriverTrips(context.Context, int, domain.TripHistoryQuery) ([]domain.Ride, error) {
	return []domain.Ride{{ID: 3}}, nil
}

func (analyticsRepository) PassengerRides(context.Context, int, domain.TripHistoryQuery) ([]domain.Ride, error) {
	return []domain.Ride{{ID: 2}}, nil
}

func (analyticsRepository) PassengerActivitySummary(context.Context, int, time.Time, time.Time) (domain.PassengerActivitySummary, error) {
	return domain.PassengerActivitySummary{ThisWeekFareCentavos: 2817, ThisWeekCompletedRides: 1}, nil
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

func (passengerReviewRepository) CreatePassengerReview(_ context.Context, review domain.PassengerReview) (domain.PassengerReview, error) {
	review.ID = 1
	return review, nil
}
