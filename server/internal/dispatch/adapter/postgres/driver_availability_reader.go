package postgres

import (
	"context"
	"fmt"

	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/app"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
)

var _ app.DriverAvailabilityReader = (*Store)(nil)

func (store *Store) OnlineDrivers(
	ctx context.Context,
	driverIDs []int,
) ([]dispatchdomain.OnlineDriver, error) {
	if err := store.validate(); err != nil {
		return nil, err
	}
	dbDriverIDs, err := toPostgresDriverIDs(driverIDs)
	if err != nil {
		return nil, err
	}
	dbLimit, err := toPostgresRideID(len(driverIDs), "driver availability limit")
	if err != nil {
		return nil, err
	}

	items, err := store.queries.ListOnlineDrivers(ctx, databasepostgres.ListOnlineDriversParams{
		DriverIds:                  dbDriverIDs,
		Limit:                      dbLimit,
		OnlineCutoff:               store.onlinePresenceCutoff(),
		AllowUnverifiedTestDrivers: store.allowUnverifiedTestDrivers,
	})
	if err != nil {
		return nil, fmt.Errorf("list online drivers: %w", err)
	}

	result := make([]dispatchdomain.OnlineDriver, 0, len(items))
	for _, item := range items {
		driver, mappingErr := fromPostgresOnlineDriver(item)
		if mappingErr != nil {
			return nil, fmt.Errorf("map online driver: %w", mappingErr)
		}
		result = append(result, driver)
	}
	return result, nil
}

func (store *Store) PublicDriverSummaries(
	ctx context.Context,
	limit int,
) ([]dispatchdomain.PublicDriverSummary, error) {
	if err := store.validate(); err != nil {
		return nil, err
	}
	dbLimit, err := toPostgresRideID(limit, "driver summary limit")
	if err != nil {
		return nil, err
	}

	items, err := store.queries.ListPublicDriverSummaries(
		ctx,
		databasepostgres.ListPublicDriverSummariesParams{
			Limit:                      dbLimit,
			OnlineCutoff:               store.onlinePresenceCutoff(),
			AllowUnverifiedTestDrivers: store.allowUnverifiedTestDrivers,
		},
	)
	if err != nil {
		return nil, fmt.Errorf("list public driver summaries: %w", err)
	}

	result := make([]dispatchdomain.PublicDriverSummary, 0, len(items))
	for _, item := range items {
		result = append(result, fromPostgresPublicDriverSummary(item))
	}
	return result, nil
}

func fromPostgresOnlineDriver(item databasepostgres.ListOnlineDriversRow) (dispatchdomain.OnlineDriver, error) {
	onboardPassengerCount, err := toNativeDriverAvailabilityCount(item.OnboardPassengerCount)
	if err != nil {
		return dispatchdomain.OnlineDriver{}, fmt.Errorf("map onboard passenger count: %w", err)
	}
	return dispatchdomain.OnlineDriver{
		ID:                    int(item.UserID),
		UserID:                int(item.UserID),
		Name:                  item.Name,
		VehicleType:           item.VehicleType,
		PlateNumber:           item.PlateNumber,
		Rating:                item.Rating,
		OnboardPassengerCount: onboardPassengerCount,
	}, nil
}

func fromPostgresPublicDriverSummary(item databasepostgres.ListPublicDriverSummariesRow) dispatchdomain.PublicDriverSummary {
	return dispatchdomain.PublicDriverSummary{
		ID:          int(item.ID),
		Name:        item.Name,
		VehicleType: item.VehicleType,
		Rating:      item.Rating,
	}
}

func toPostgresDriverIDs(values []int) ([]int32, error) {
	result := make([]int32, 0, len(values))
	for _, value := range values {
		converted, err := toPostgresRideID(value, "driver id")
		if err != nil {
			return nil, err
		}
		result = append(result, converted)
	}
	return result, nil
}

func toNativeDriverAvailabilityCount(value int64) (int, error) {
	if value < 0 || value > int64(^uint(0)>>1) {
		return 0, fmt.Errorf("onboard passenger count %d is outside native integer range", value)
	}
	return int(value), nil
}
