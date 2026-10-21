package postgres

import (
	"context"
	"errors"
	"fmt"
	"math"
	"time"

	ports "github.com/Easy-Bao/DrivingApp/server/internal/modules/review/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/review/domain"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ ports.ReviewRepository = (*ReviewRepository)(nil)

type ReviewRepository struct {
	queries *databasepostgres.Queries
}

func NewReviewRepository(pool *pgxpool.Pool) (*ReviewRepository, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &ReviewRepository{queries: databasepostgres.New(pool)}, nil
}

func (repository *ReviewRepository) ReviewableRide(
	ctx context.Context,
	rideID int,
) (domain.ReviewableRide, error) {
	dbRideID, err := toPostgresID(rideID, "ride id")
	if err != nil {
		return domain.ReviewableRide{}, domain.ErrReviewNotAllowed
	}
	item, err := repository.queries.GetRideReviewContext(ctx, dbRideID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.ReviewableRide{}, domain.ErrReviewNotAllowed
	}
	if err != nil {
		return domain.ReviewableRide{}, fmt.Errorf("read ride review context: %w", err)
	}
	var driverID *int
	if item.DriverID.Valid {
		value := int(item.DriverID.Int32)
		driverID = &value
	}
	return domain.ReviewableRide{
		Status:      item.Status,
		PassengerID: int(item.PassengerID),
		DriverID:    driverID,
	}, nil
}

func (repository *ReviewRepository) DriverReviews(
	ctx context.Context,
	driverID, limit, offset int,
) ([]domain.Review, error) {
	dbDriverID, err := toPostgresID(driverID, "driver id")
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
	for _, item := range items {
		review, mappingErr := fromPostgresReview(item)
		if mappingErr != nil {
			return nil, fmt.Errorf("map driver review: %w", mappingErr)
		}
		result = append(result, review)
	}
	return result, nil
}

func (repository *ReviewRepository) DriverReviewForRide(
	ctx context.Context,
	rideID, passengerID int,
) (domain.Review, error) {
	dbRideID, err := toPostgresID(rideID, "ride id")
	if err != nil {
		return domain.Review{}, domain.ErrReviewNotFound
	}
	dbPassengerID, err := toPostgresID(passengerID, "passenger id")
	if err != nil {
		return domain.Review{}, domain.ErrReviewNotFound
	}
	item, err := repository.queries.GetDriverReviewByRideAndPassenger(ctx, databasepostgres.GetDriverReviewByRideAndPassengerParams{
		RideID:      pgtype.Int4{Int32: dbRideID, Valid: true},
		PassengerID: dbPassengerID,
	})
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Review{}, domain.ErrReviewNotFound
	}
	if err != nil {
		return domain.Review{}, fmt.Errorf("find passenger review for ride: %w", err)
	}
	review, err := fromPostgresCreatedReview(item)
	if err != nil {
		return domain.Review{}, fmt.Errorf("map passenger review for ride: %w", err)
	}
	return review, nil
}

func (repository *ReviewRepository) CreateReview(
	ctx context.Context,
	value domain.Review,
) (domain.Review, error) {
	rideID, err := toPostgresID(value.RideID, "ride id")
	if err != nil {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}
	driverID, err := toPostgresID(value.DriverID, "driver id")
	if err != nil {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}
	passengerID, err := toPostgresID(value.PassengerID, "passenger id")
	if err != nil {
		return domain.Review{}, domain.ErrReviewNotAllowed
	}
	queryRideID := pgtype.Int4{Int32: rideID, Valid: true}
	exists, err := repository.queries.HasReviewForRide(ctx, queryRideID)
	if err != nil {
		return domain.Review{}, fmt.Errorf("check existing driver review: %w", err)
	}
	if exists {
		return repository.existingDriverReview(ctx, rideID)
	}
	passengerName, err := repository.queries.GetPassengerName(ctx, passengerID)
	if err != nil {
		return domain.Review{}, fmt.Errorf("load passenger name for driver review: %w", err)
	}
	value.PassengerName = passengerName
	item, err := repository.queries.CreateReview(ctx, databasepostgres.CreateReviewParams{
		RideID:        queryRideID,
		DriverID:      driverID,
		PassengerID:   passengerID,
		PassengerName: reviewText(value.PassengerName),
		Rating:        value.Rating,
		Comment:       reviewText(value.Comment),
	})
	if err != nil {
		if isUniqueViolation(err) {
			return repository.existingDriverReview(ctx, rideID)
		}
		return domain.Review{}, fmt.Errorf("create driver review: %w", err)
	}
	review, err := fromPostgresCreatedReview(item)
	if err != nil {
		return domain.Review{}, fmt.Errorf("map created driver review: %w", err)
	}
	return review, nil
}

func (repository *ReviewRepository) CreatePassengerReview(
	ctx context.Context,
	value domain.PassengerReview,
) (domain.PassengerReview, error) {
	rideID, err := toPostgresID(value.RideID, "ride id")
	if err != nil {
		return domain.PassengerReview{}, domain.ErrReviewNotAllowed
	}
	driverID, err := toPostgresID(value.DriverID, "driver id")
	if err != nil {
		return domain.PassengerReview{}, domain.ErrReviewNotAllowed
	}
	passengerID, err := toPostgresID(value.PassengerID, "passenger id")
	if err != nil {
		return domain.PassengerReview{}, domain.ErrReviewNotAllowed
	}
	exists, err := repository.queries.HasPassengerReviewForRide(ctx, rideID)
	if err != nil {
		return domain.PassengerReview{}, fmt.Errorf("check existing passenger review: %w", err)
	}
	if exists {
		return repository.existingPassengerReview(ctx, rideID)
	}
	item, err := repository.queries.CreatePassengerReview(ctx, databasepostgres.CreatePassengerReviewParams{
		RideID:      rideID,
		DriverID:    driverID,
		PassengerID: passengerID,
		Rating:      value.Rating,
		Comment:     reviewText(value.Comment),
	})
	if err != nil {
		if isUniqueViolation(err) {
			return repository.existingPassengerReview(ctx, rideID)
		}
		return domain.PassengerReview{}, fmt.Errorf("create passenger review: %w", err)
	}
	review, err := fromPostgresPassengerReview(item)
	if err != nil {
		return domain.PassengerReview{}, fmt.Errorf("map created passenger review: %w", err)
	}
	return review, nil
}

func (repository *ReviewRepository) existingDriverReview(
	ctx context.Context,
	rideID int32,
) (domain.Review, error) {
	item, err := repository.queries.GetReviewByRide(ctx, pgtype.Int4{Int32: rideID, Valid: true})
	if err != nil {
		return domain.Review{}, fmt.Errorf("load existing driver review: %w", err)
	}
	review, err := fromPostgresCreatedReview(item)
	if err != nil {
		return domain.Review{}, fmt.Errorf("map existing driver review: %w", err)
	}
	return review, nil
}

func (repository *ReviewRepository) existingPassengerReview(
	ctx context.Context,
	rideID int32,
) (domain.PassengerReview, error) {
	item, err := repository.queries.GetPassengerReviewByRide(ctx, rideID)
	if err != nil {
		return domain.PassengerReview{}, fmt.Errorf("load existing passenger review: %w", err)
	}
	review, err := fromPostgresPassengerReview(item)
	if err != nil {
		return domain.PassengerReview{}, fmt.Errorf("map existing passenger review: %w", err)
	}
	return review, nil
}

func fromPostgresReview(item databasepostgres.ListDriverReviewsRow) (domain.Review, error) {
	if !item.CreatedAt.Valid {
		return domain.Review{}, errors.New("review creation time is null")
	}
	return domain.Review{
		ID:            int(item.ID),
		RideID:        optionalID(item.RideID),
		DriverID:      int(item.DriverID),
		PassengerID:   int(item.PassengerID),
		PassengerName: item.PassengerName,
		Rating:        item.Rating,
		Comment:       textValue(item.Comment),
		CreatedAt:     item.CreatedAt.Time.UTC().Format(time.RFC3339),
	}, nil
}

func fromPostgresCreatedReview(item databasepostgres.Review) (domain.Review, error) {
	if !item.CreatedAt.Valid {
		return domain.Review{}, errors.New("review creation time is null")
	}
	return domain.Review{
		ID:            int(item.ID),
		RideID:        optionalID(item.RideID),
		DriverID:      int(item.DriverID),
		PassengerID:   int(item.PassengerID),
		PassengerName: textValue(item.PassengerName),
		Rating:        item.Rating,
		Comment:       textValue(item.Comment),
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
		Comment:     textValue(item.Comment),
		CreatedAt:   item.CreatedAt.Time.UTC().Format(time.RFC3339),
	}, nil
}

func toPostgresID(value int, field string) (int32, error) {
	if value <= 0 || int64(value) > math.MaxInt32 {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

func toPostgresPaginationValue(value int, field string) (int32, error) {
	if value < 0 || int64(value) > math.MaxInt32 {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

func optionalID(value pgtype.Int4) int {
	if !value.Valid {
		return 0
	}
	return int(value.Int32)
}

func reviewText(value string) pgtype.Text {
	if value == "" {
		return pgtype.Text{}
	}
	return pgtype.Text{String: value, Valid: true}
}

func textValue(value pgtype.Text) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

func isUniqueViolation(err error) bool {
	var databaseError *pgconn.PgError
	return errors.As(err, &databaseError) && databaseError.Code == "23505"
}
