package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// ReviewStore reads driver reviews and records a passenger's review.
type ReviewStore interface {
	DriverReviews(ctx context.Context, driverID int, limit, offset int) ([]domain.Review, error)
	CreateReview(ctx context.Context, review domain.Review) (domain.Review, error)
}

// PassengerReviewStore records a driver's review of a passenger.
type PassengerReviewStore interface {
	CreatePassengerReview(ctx context.Context, review domain.PassengerReview) (domain.PassengerReview, error)
}
