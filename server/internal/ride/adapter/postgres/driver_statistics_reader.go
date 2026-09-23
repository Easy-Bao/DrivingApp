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
	stats, err := fromPostgresDriverStats(driverID, row)
	if err != nil {
		return domain.DriverStats{}, fmt.Errorf("map driver statistics: %w", err)
	}
	return stats, nil
}

func fromPostgresDriverStats(driverID int, row databasepostgres.GetDriverStatsRow) (domain.DriverStats, error) {
	totalTrips, err := toNativeRideCount(row.TotalTrips, "total trips")
	if err != nil {
		return domain.DriverStats{}, fmt.Errorf("map total trips: %w", err)
	}
	completedTrips, err := toNativeRideCount(row.CompletedTrips, "completed trips")
	if err != nil {
		return domain.DriverStats{}, fmt.Errorf("map completed trips: %w", err)
	}
	activeTrips, err := toNativeRideCount(row.ActiveTrips, "active trips")
	if err != nil {
		return domain.DriverStats{}, fmt.Errorf("map active trips: %w", err)
	}
	todayCompletedTrips, err := toNativeRideCount(row.TodayCompletedTrips, "today completed trips")
	if err != nil {
		return domain.DriverStats{}, fmt.Errorf("map today completed trips: %w", err)
	}
	ratingDistribution, err := mapRatingDistribution(row)
	if err != nil {
		return domain.DriverStats{}, fmt.Errorf("map rating distribution: %w", err)
	}
	return domain.DriverStats{
		DriverID:            driverID,
		TotalTrips:          totalTrips,
		CompletedTrips:      completedTrips,
		ActiveTrips:         activeTrips,
		TotalEarnings:       row.TotalEarningsAmount,
		TodayCompletedTrips: todayCompletedTrips,
		TodayEarnings:       row.TodayEarningsAmount,
		AverageRating:       row.AverageRating,
		RatingDistribution:  ratingDistribution,
	}, nil
}

func mapRatingDistribution(row databasepostgres.GetDriverStatsRow) ([5]int, error) {
	values := [5]int64{
		row.OneStarCount,
		row.TwoStarCount,
		row.ThreeStarCount,
		row.FourStarCount,
		row.FiveStarCount,
	}
	result := [5]int{}
	for index, value := range values {
		count, err := toNativeRideCount(value, "rating count")
		if err != nil {
			return [5]int{}, fmt.Errorf("rating index %d: %w", index, err)
		}
		result[index] = count
	}
	return result, nil
}

func toNativeRideCount(value int64, field string) (int, error) {
	if value < 0 || value > int64(^uint(0)>>1) {
		return 0, fmt.Errorf("%s %d is outside native integer range", field, value)
	}
	return int(value), nil
}
