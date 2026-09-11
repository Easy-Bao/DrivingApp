package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
	"github.com/jackc/pgx/v5/pgtype"
)

var (
	_ ports.ReviewStore          = (*RideRepository)(nil)
	_ ports.PassengerReviewStore = (*RideRepository)(nil)
)

func (repository *RideRepository) DriverReviews(
	ctx context.Context,
	driverID, limit, offset int,
) ([]domain.Review, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	dbDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return nil, err
	}
	dbLimit, err := toPostgresPaginationValue(limit, "limit")
	if err != nil {
		return nil, err
	}
	dbOffset, err := toPostgresPaginationValue(offset, "offset")
	if err != nil {
		return nil, err
	}

	items, err := repository.queries.ListDriverReviews(ctx, databasepostgres.ListDriverReviewsParams{
		DriverID: dbDriverID,
		Limit:    dbLimit,
		Offset:   dbOffset,
	})
	if err != nil {
		return nil, fmt.Errorf("list driver reviews: %w", err)
	}

	result := make([]domain.Review, 0, len(items))
	for index := len(items) - 1; index >= 0; index-- {
		review, mappingErr := fromPostgresReview(items[index])
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, review)
	}
	return result, nil
}

func (repository *RideRepository) CreateReview(ctx context.Context, value domain.Review) (domain.Review, error) {
	trip, err := repository.Get(ctx, value.RideID)
	if err != nil || !canCreateReview(trip, value.PassengerID, value.DriverID) {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}

	rideID, err := toPostgresRideID(value.RideID, "ride id")
	if err != nil {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}
	driverID, err := toPostgresRideID(value.DriverID, "driver id")
	if err != nil {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}
	passengerID, err := toPostgresRideID(value.PassengerID, "passenger id")
	if err != nil {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}

	exists, err := repository.queries.HasReviewForRide(ctx, pgtype.Int4{Int32: rideID, Valid: true})
	if err != nil {
		return domain.Review{}, fmt.Errorf("check existing driver review: %w", err)
	}
	if exists {
		return domain.Review{}, domain.ErrReviewAlreadySubmitted
	}
	if passengerName, nameErr := repository.queries.GetPassengerName(ctx, passengerID); nameErr == nil {
		value.PassengerName = passengerName
	}

	item, err := repository.queries.CreateReview(ctx, databasepostgres.CreateReviewParams{
		RideID:        pgtype.Int4{Int32: rideID, Valid: true},
		DriverID:      driverID,
		PassengerID:   passengerID,
		PassengerName: rideText(value.PassengerName),
		Rating:        value.Rating,
		Comment:       rideText(value.Comment),
	})
	if err != nil {
		if isPostgresUniqueViolation(err) {
			return domain.Review{}, domain.ErrReviewAlreadySubmitted
		}
		return domain.Review{}, fmt.Errorf("create driver review: %w", err)
	}
	return fromPostgresCreatedReview(item)
}

func (repository *RideRepository) CreatePassengerReview(
	ctx context.Context,
	value domain.PassengerReview,
) (domain.PassengerReview, error) {
	trip, err := repository.Get(ctx, value.RideID)
	if err != nil || !canCreateReview(trip, value.PassengerID, value.DriverID) {
		return domain.PassengerReview{}, domain.ErrReviewNotAllowed
	}

	rideID, err := toPostgresRideID(value.RideID, "ride id")
	if err != nil {
		return domain.PassengerReview{}, domain.ErrReviewNotAllowed
	}
	driverID, err := toPostgresRideID(value.DriverID, "driver id")
	if err != nil {
		return domain.PassengerReview{}, domain.ErrReviewNotAllowed
	}
	passengerID, err := toPostgresRideID(value.PassengerID, "passenger id")
	if err != nil {
		return domain.PassengerReview{}, domain.ErrReviewNotAllowed
	}

	exists, err := repository.queries.HasPassengerReviewForRide(ctx, rideID)
	if err != nil {
		return domain.PassengerReview{}, fmt.Errorf("check existing passenger review: %w", err)
	}
	if exists {
		return domain.PassengerReview{}, domain.ErrReviewAlreadySubmitted
	}

	item, err := repository.queries.CreatePassengerReview(ctx, databasepostgres.CreatePassengerReviewParams{
		RideID:      rideID,
		DriverID:    driverID,
		PassengerID: passengerID,
		Rating:      value.Rating,
		Comment:     rideText(value.Comment),
	})
	if err != nil {
		if isPostgresUniqueViolation(err) {
			return domain.PassengerReview{}, domain.ErrReviewAlreadySubmitted
		}
		return domain.PassengerReview{}, fmt.Errorf("create passenger review: %w", err)
	}
	return fromPostgresPassengerReview(item)
}

func canCreateReview(ride domain.Ride, passengerID, driverID int) bool {
	if ride.Status != string(domain.RideCompleted) || ride.PassengerID != passengerID {
		return false
	}
	if ride.DriverID == nil {
		return false
	}
	return *ride.DriverID == driverID
}

func fromPostgresReview(item databasepostgres.ListDriverReviewsRow) (domain.Review, error) {
	if !item.CreatedAt.Valid {
		return domain.Review{}, errors.New("review creation time is null")
	}
	return domain.Review{
		ID:            int(item.ID),
		RideID:        postgresOptionalID(item.RideID),
		DriverID:      int(item.DriverID),
		PassengerID:   int(item.PassengerID),
		PassengerName: item.PassengerName,
		Rating:        item.Rating,
		Comment:       rideTextValue(item.Comment),
		CreatedAt:     item.CreatedAt.Time.UTC().Format(time.RFC3339),
	}, nil
}

func fromPostgresCreatedReview(item databasepostgres.Review) (domain.Review, error) {
	if !item.CreatedAt.Valid {
		return domain.Review{}, errors.New("review creation time is null")
	}
	return domain.Review{
		ID:            int(item.ID),
		RideID:        postgresOptionalID(item.RideID),
		DriverID:      int(item.DriverID),
		PassengerID:   int(item.PassengerID),
		PassengerName: rideTextValue(item.PassengerName),
		Rating:        item.Rating,
		Comment:       rideTextValue(item.Comment),
		CreatedAt:     item.CreatedAt.Time.UTC().Format(time.RFC3339),
	}, nil
}

func fromPostgresPassengerReview(item databasepostgres.PassengerReview) (domain.PassengerReview, error) {
	if !item.CreatedAt.Valid {
		return domain.PassengerReview{}, errors.New("passenger review creation time is null")
	}
	return domain.PassengerReview{
		ID:          int(item.ID),
		RideID:      int(item.RideID),
		DriverID:    int(item.DriverID),
		PassengerID: int(item.PassengerID),
		Rating:      item.Rating,
		Comment:     rideTextValue(item.Comment),
		CreatedAt:   item.CreatedAt.Time.UTC().Format(time.RFC3339),
	}, nil
}

func postgresOptionalID(value pgtype.Int4) int {
	if !value.Valid {
		return 0
	}
	return int(value.Int32)
}
