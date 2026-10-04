package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// ReviewStore isolates driver-review reads and passenger-review writes from the
// persistence adapter.
type ReviewStore interface {
	DriverReviews(ctx context.Context, driverID int, limit, offset int) ([]domain.Review, error)
	CreateReview(ctx context.Context, review domain.Review) (domain.Review, error)
}

// PassengerReviewStore isolates driver-to-passenger review writes.
type PassengerReviewStore interface {
	CreatePassengerReview(ctx context.Context, review domain.PassengerReview) (domain.PassengerReview, error)
}

// SafetyReportStore persists reports separately from service-quality ratings.
// The ride ID remains the evidence link to lifecycle, location, and chat data.
type SafetyReportStore interface {
	CreateSafetyReport(ctx context.Context, report domain.SafetyReport) (domain.SafetyReport, error)
}
