package postgres

import (
	"context"
	"fmt"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
	"github.com/jackc/pgx/v5/pgtype"
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
	dbPassengerID, err := toPostgresRideID(passengerID, "passenger id")
	if err != nil {
		return domain.PassengerActivitySummary{}, err
	}
	row, err := repository.queries.GetPassengerActivitySummary(ctx, databasepostgres.GetPassengerActivitySummaryParams{
		WeekStart:   pgtype.Timestamptz{Time: weekStart.UTC(), Valid: true},
		WeekEnd:     pgtype.Timestamptz{Time: weekEnd.UTC(), Valid: true},
		PassengerID: dbPassengerID,
	})
	if err != nil {
		return domain.PassengerActivitySummary{}, fmt.Errorf("load passenger activity summary: %w", err)
	}
	return fromPostgresPassengerActivitySummary(row)
}

func fromPostgresPassengerActivitySummary(
	row databasepostgres.GetPassengerActivitySummaryRow,
) (domain.PassengerActivitySummary, error) {
	completedRides, err := toNativeRideCount(row.ThisWeekCompletedRides, "completed rides")
	if err != nil {
		return domain.PassengerActivitySummary{}, err
	}
	return domain.PassengerActivitySummary{
		ThisWeekFareCentavos:   row.ThisWeekFareCentavos,
		ThisWeekCompletedRides: completedRides,
	}, nil
}
