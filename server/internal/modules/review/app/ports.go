package app

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/review/domain"
)

type ReviewRepository interface {
	ReviewableRide(ctx context.Context, rideID int) (domain.ReviewableRide, error)
	DriverReviews(ctx context.Context, driverID, limit, offset int) ([]domain.Review, error)
	CreateReview(ctx context.Context, review domain.Review) (domain.Review, error)
	CreatePassengerReview(ctx context.Context, review domain.PassengerReview) (domain.PassengerReview, error)
}
