package postgres

import (
	"context"
	"fmt"
	"time"

	ports "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
)

var _ ports.PassengerActivityReader = (*RideRepository)(nil)

func (repository *RideRepository) PassengerActivitySummary(
	ctx context.Context,
	passengerID int,
	weekStart, weekEnd time.Time,
) (domain.PassengerActivitySummary, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.PassengerActivitySummary{}, err
	}
	dbPassengerID, err := pgutil.ToPositiveInt32(passengerID, "passenger id")
	if err != nil {
		return domain.PassengerActivitySummary{}, err
	}
	row, err := repository.queries.GetPassengerActivitySummary(ctx, databasepostgres.GetPassengerActivitySummaryParams{
		WeekStart:   pgutil.ToTimestamptz(weekStart.UTC()),
		WeekEnd:     pgutil.ToTimestamptz(weekEnd.UTC()),
		PassengerID: dbPassengerID,
	})
	if err != nil {
		return domain.PassengerActivitySummary{}, fmt.Errorf("load passenger activity summary: %w", err)
	}
	activity, err := fromPostgresPassengerActivitySummary(row)
	if err != nil {
		return domain.PassengerActivitySummary{}, fmt.Errorf("map passenger activity summary: %w", err)
	}
	return activity, nil
}

func fromPostgresPassengerActivitySummary(
	row databasepostgres.GetPassengerActivitySummaryRow,
) (domain.PassengerActivitySummary, error) {
	completedRides, err := toNativeRideCount(row.ThisWeekCompletedRides, "completed rides")
	if err != nil {
		return domain.PassengerActivitySummary{}, fmt.Errorf("map completed rides: %w", err)
	}
	return domain.PassengerActivitySummary{
		ThisWeekFareAmount:     row.ThisWeekFareAmount,
		ThisWeekCompletedRides: completedRides,
	}, nil
}
