package postgres

import (
	"context"
	"fmt"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

var _ ports.DriverAvailabilityReader = (*RideRepository)(nil)

func (repository *RideRepository) OnlineDrivers(
	ctx context.Context,
	driverIDs []int,
) ([]domain.OnlineDriver, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	dbDriverIDs, err := toPostgresRideIDs(driverIDs, "driver id")
	if err != nil {
		return nil, err
	}
	dbLimit, err := toPostgresPaginationValue(len(driverIDs), "driver availability limit")
	if err != nil {
		return nil, err
	}

	items, err := repository.queries.ListOnlineDrivers(ctx, databasepostgres.ListOnlineDriversParams{
		DriverIds: dbDriverIDs,
		Limit:     dbLimit,
	})
	if err != nil {
		return nil, fmt.Errorf("list online drivers: %w", err)
	}

	result := make([]domain.OnlineDriver, 0, len(items))
	for _, item := range items {
		driver, mappingErr := fromPostgresOnlineDriver(item)
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, driver)
	}
	return result, nil
}

func (repository *RideRepository) PublicDriverSummaries(
	ctx context.Context,
	limit int,
) ([]domain.PublicDriverSummary, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	dbLimit, err := toPostgresPaginationValue(limit, "driver summary limit")
	if err != nil {
		return nil, err
	}

	items, err := repository.queries.ListPublicDriverSummaries(ctx, dbLimit)
	if err != nil {
		return nil, fmt.Errorf("list public driver summaries: %w", err)
	}

	result := make([]domain.PublicDriverSummary, 0, len(items))
	for _, item := range items {
		result = append(result, fromPostgresPublicDriverSummary(item))
	}
	return result, nil
}

func fromPostgresOnlineDriver(item databasepostgres.ListOnlineDriversRow) (domain.OnlineDriver, error) {
	onboardPassengerCount, err := toNativeRideCount(item.OnboardPassengerCount, "onboard passenger count")
	if err != nil {
		return domain.OnlineDriver{}, err
	}
	return domain.OnlineDriver{
		ID:                    int(item.UserID),
		UserID:                int(item.UserID),
		Name:                  item.Name,
		VehicleType:           item.VehicleType,
		PlateNumber:           item.PlateNumber,
		Rating:                item.Rating,
		OnboardPassengerCount: onboardPassengerCount,
	}, nil
}

func fromPostgresPublicDriverSummary(item databasepostgres.ListPublicDriverSummariesRow) domain.PublicDriverSummary {
	return domain.PublicDriverSummary{
		ID:          int(item.ID),
		Name:        item.Name,
		VehicleType: item.VehicleType,
		Rating:      item.Rating,
	}
}

func toPostgresRideIDs(values []int, field string) ([]int32, error) {
	result := make([]int32, 0, len(values))
	for _, value := range values {
		converted, err := toPostgresRideID(value, field)
		if err != nil {
			return nil, err
		}
		result = append(result, converted)
	}
	return result, nil
}
