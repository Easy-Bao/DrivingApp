package app

import (
	"context"
	"errors"
	"fmt"
	"slices"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/review/domain"
)

var ErrPersistenceUnavailable = errors.New("review persistence is unavailable")

type Service struct {
	repository ReviewRepository
}

func NewService(repository ReviewRepository) *Service {
	return &Service{repository: repository}
}

func (service *Service) DriverReviews(
	ctx context.Context,
	driverID, limit, offset int,
) ([]domain.Review, error) {
	if service == nil || service.repository == nil {
		return nil, ErrPersistenceUnavailable
	}
	reviews, err := service.repository.DriverReviews(ctx, driverID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("load driver reviews: %w", err)
	}
	return slices.Clone(reviews), nil
}

func (service *Service) PassengerDriverReviewForRide(
	ctx context.Context,
	rideID, passengerID int,
) (domain.Review, error) {
	if service == nil || service.repository == nil {
		return domain.Review{}, ErrPersistenceUnavailable
	}
	if rideID <= 0 || passengerID <= 0 {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}
	ride, err := service.repository.ReviewableRide(ctx, rideID)
	if err != nil {
		return domain.Review{}, fmt.Errorf("load ride for passenger review: %w", err)
	}
	if ride.Status != "completed" || ride.PassengerID != passengerID || ride.DriverID == nil {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}
	review, err := service.repository.DriverReviewForRide(ctx, rideID, passengerID)
	if err != nil {
		return domain.Review{}, fmt.Errorf("load passenger review for ride: %w", err)
	}
	return review, nil
}

func (service *Service) CreateReview(ctx context.Context, review domain.Review) (domain.Review, error) {
	if service == nil || service.repository == nil {
		return domain.Review{}, ErrPersistenceUnavailable
	}
	if err := domain.ValidateRating(review.Rating); err != nil {
		return domain.Review{}, err
	}
	if err := service.validateReviewableRide(ctx, review.RideID, review.PassengerID, review.DriverID); err != nil {
		return domain.Review{}, err
	}
	created, err := service.repository.CreateReview(ctx, review)
	if err != nil {
		return domain.Review{}, fmt.Errorf("create driver review: %w", err)
	}
	return created, nil
}

func (service *Service) CreatePassengerReview(
	ctx context.Context,
	review domain.PassengerReview,
) (domain.PassengerReview, error) {
	if service == nil || service.repository == nil {
		return domain.PassengerReview{}, ErrPersistenceUnavailable
	}
	if err := domain.ValidateRating(review.Rating); err != nil {
		return domain.PassengerReview{}, err
	}
	if err := service.validateReviewableRide(ctx, review.RideID, review.PassengerID, review.DriverID); err != nil {
		return domain.PassengerReview{}, err
	}
	created, err := service.repository.CreatePassengerReview(ctx, review)
	if err != nil {
		return domain.PassengerReview{}, fmt.Errorf("create passenger review: %w", err)
	}
	return created, nil
}

func (service *Service) validateReviewableRide(
	ctx context.Context,
	rideID, passengerID, driverID int,
) error {
	ride, err := service.repository.ReviewableRide(ctx, rideID)
	if err != nil {
		return fmt.Errorf("load ride for review: %w", err)
	}
	if !ride.AllowsReview(passengerID, driverID) {
		return domain.ErrReviewNotAllowed
	}
	return nil
}
