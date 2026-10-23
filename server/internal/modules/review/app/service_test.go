package app

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/review/domain"
)

type reviewRepositoryStub struct {
	ride                  domain.ReviewableRide
	review                domain.Review
	passengerReview       domain.PassengerReview
	requestedDriverID     int
	requestedReviewRideID int
}

func (repository *reviewRepositoryStub) ReviewableRide(_ context.Context, rideID int) (domain.ReviewableRide, error) {
	repository.requestedReviewRideID = rideID
	return repository.ride, nil
}

func (repository *reviewRepositoryStub) DriverReviewForRide(
	_ context.Context,
	rideID, passengerID int,
) (domain.Review, error) {
	repository.requestedReviewRideID = rideID
	if repository.review.ID == 0 || repository.review.PassengerID != passengerID {
		return domain.Review{}, domain.ErrReviewNotFound
	}
	return repository.review, nil
}

func (repository *reviewRepositoryStub) DriverReviews(
	context.Context,
	int,
	domain.ReviewQuery,
) ([]domain.Review, error) {
	return []domain.Review{repository.review}, nil
}

func (repository *reviewRepositoryStub) CreateReview(
	_ context.Context,
	review domain.Review,
) (domain.Review, error) {
	repository.review = review
	repository.review.ID = 1
	return repository.review, nil
}

func (repository *reviewRepositoryStub) CreatePassengerReview(
	_ context.Context,
	review domain.PassengerReview,
) (domain.PassengerReview, error) {
	repository.passengerReview = review
	repository.passengerReview.ID = 2
	return repository.passengerReview, nil
}

func TestCreateReviewRequiresCompletedRideParticipantsAndValidRating(t *testing.T) {
	driverID := 9
	repository := &reviewRepositoryStub{
		ride: domain.ReviewableRide{Status: "completed", PassengerID: 4, DriverID: &driverID},
	}
	service := NewService(repository)

	review, err := service.CreateReview(context.Background(), domain.Review{
		RideID: 7, PassengerID: 4, DriverID: 9, Rating: 5,
	})
	if err != nil || review.ID != 1 || repository.requestedReviewRideID != 7 {
		t.Fatalf("CreateReview() = %#v, %v", review, err)
	}

	_, err = service.CreateReview(context.Background(), domain.Review{
		RideID: 7, PassengerID: 4, DriverID: 9, Rating: 6,
	})
	if !errors.Is(err, domain.ErrInvalidRating) {
		t.Fatalf("invalid rating error = %v, want ErrInvalidRating", err)
	}

	_, err = service.CreateReview(context.Background(), domain.Review{
		RideID: 7, PassengerID: 5, DriverID: 9, Rating: 5,
	})
	if !errors.Is(err, domain.ErrReviewNotAllowed) {
		t.Fatalf("wrong participant error = %v, want ErrReviewNotAllowed", err)
	}
}

func TestCreatePassengerReviewUsesTheSameRideEligibilityRule(t *testing.T) {
	driverID := 9
	repository := &reviewRepositoryStub{
		ride: domain.ReviewableRide{Status: "completed", PassengerID: 4, DriverID: &driverID},
	}
	service := NewService(repository)

	review, err := service.CreatePassengerReview(context.Background(), domain.PassengerReview{
		RideID: 7, PassengerID: 4, DriverID: 9, Rating: 4,
	})
	if err != nil || review.ID != 2 {
		t.Fatalf("CreatePassengerReview() = %#v, %v", review, err)
	}

	repository.ride.Status = "cancelled"
	_, err = service.CreatePassengerReview(context.Background(), domain.PassengerReview{
		RideID: 7, PassengerID: 4, DriverID: 9, Rating: 4,
	})
	if !errors.Is(err, domain.ErrReviewNotAllowed) {
		t.Fatalf("cancelled ride error = %v, want ErrReviewNotAllowed", err)
	}
}

func TestDriverReviewsReturnAnIndependentSlice(t *testing.T) {
	repository := &reviewRepositoryStub{review: domain.Review{ID: 3}}
	service := NewService(repository)

	reviews, err := service.DriverReviews(context.Background(), 9, domain.ReviewQuery{Limit: 20})
	if err != nil {
		t.Fatalf("DriverReviews() error = %v", err)
	}
	reviews[0].ID = 99
	if repository.review.ID != 3 {
		t.Fatalf("repository review changed through result slice: %#v", repository.review)
	}
}

func TestPassengerCanReadOnlyTheirSubmittedReviewForACompletedRide(t *testing.T) {
	driverID := 9
	repository := &reviewRepositoryStub{
		ride:   domain.ReviewableRide{Status: "completed", PassengerID: 4, DriverID: &driverID},
		review: domain.Review{ID: 3, RideID: 7, PassengerID: 4, DriverID: 9, Rating: 5},
	}
	service := NewService(repository)

	review, err := service.PassengerDriverReviewForRide(context.Background(), 7, 4)
	if err != nil || review.ID != 3 || repository.requestedReviewRideID != 7 {
		t.Fatalf("PassengerDriverReviewForRide() = %#v, %v", review, err)
	}
	_, err = service.PassengerDriverReviewForRide(context.Background(), 7, 5)
	if !errors.Is(err, domain.ErrReviewNotAllowed) {
		t.Fatalf("wrong passenger error = %v, want ErrReviewNotAllowed", err)
	}
}
