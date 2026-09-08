package postgres

import (
	"context"
	"fmt"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

func (repository *PostgresRideRepository) DriverEarnings(
	ctx context.Context,
	driverID int,
	monthStart, monthEnd time.Time,
) ([]domain.DriverEarning, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	postgresDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return nil, err
	}
	items, err := repository.queries.ListDriverEarnings(ctx, databasepostgres.ListDriverEarningsParams{
		DriverID:   pgtype.Int4{Int32: postgresDriverID, Valid: true},
		MonthStart: postgresBidTimestamp(monthStart.UTC()),
		MonthEnd:   postgresBidTimestamp(monthEnd.UTC()),
	})
	if err != nil {
		return nil, fmt.Errorf("list driver earnings: %w", err)
	}
	result := make([]domain.DriverEarning, 0, len(items))
	for _, item := range items {
		entry, mappingErr := fromPostgresDriverEarning(item)
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, entry)
	}
	return result, nil
}

func fromPostgresDriverEarning(item databasepostgres.ListDriverEarningsRow) (domain.DriverEarning, error) {
	if !item.CreatedAt.Valid {
		return domain.DriverEarning{}, fmt.Errorf("driver earning creation time is null")
	}
	completedAt := item.CreatedAt.Time
	if item.CompletedAt.Valid {
		completedAt = item.CompletedAt.Time
	}
	return domain.DriverEarning{
		CompletedAt:    completedAt.UTC(),
		PayoutCentavos: item.DriverPayoutCentavos,
	}, nil
}
