package postgres

import (
	"context"
	"fmt"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

var _ ports.DriverStatisticsReader = (*RideRepository)(nil)

func (repository *RideRepository) DriverStats(
	ctx context.Context,
	driverID int,
	dayStart, dayEnd time.Time,
) (domain.DriverStats, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.DriverStats{}, err
	}
	dbDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return domain.DriverStats{}, err
	}
	row, err := repository.queries.GetDriverStats(ctx, databasepostgres.GetDriverStatsParams{
		DayStart: bidTimestamp(dayStart.UTC()),
		DayEnd:   bidTimestamp(dayEnd.UTC()),
		DriverID: dbDriverID,
	})
	if err != nil {
		return domain.DriverStats{}, fmt.Errorf("load driver statistics: %w", err)
	}
	return fromPostgresDriverStats(driverID, row)
}

func fromPostgresDriverStats(driverID int, row databasepostgres.GetDriverStatsRow) (domain.DriverStats, error) {
	totalTrips, err := toNativeRideCount(row.TotalTrips, "total trips")
	if err != nil {
		return domain.DriverStats{}, err
	}
	completedTrips, err := toNativeRideCount(row.CompletedTrips, "completed trips")
	if err != nil {
		return domain.DriverStats{}, err
	}
	activeTrips, err := toNativeRideCount(row.ActiveTrips, "active trips")
	if err != nil {
		return domain.DriverStats{}, err
	}
	todayCompletedTrips, err := toNativeRideCount(row.TodayCompletedTrips, "today completed trips")
	if err != nil {
		return domain.DriverStats{}, err
	}
	return domain.DriverStats{
		DriverID:            driverID,
		TotalTrips:          totalTrips,
		CompletedTrips:      completedTrips,
		ActiveTrips:         activeTrips,
		TotalEarnings:       row.TotalEarningsCentavos,
		TodayCompletedTrips: todayCompletedTrips,
		TodayEarnings:       row.TodayEarningsCentavos,
		AverageRating:       row.AverageRating,
	}, nil
}

func toNativeRideCount(value int64, field string) (int, error) {
	if value < 0 || value > int64(^uint(0)>>1) {
		return 0, fmt.Errorf("%s %d is outside native integer range", field, value)
	}
	return int(value), nil
}
