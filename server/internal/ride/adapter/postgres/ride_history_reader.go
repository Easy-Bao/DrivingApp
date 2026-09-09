package postgres

import (
	"context"
	"fmt"
	"strings"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

var (
	_ domain.RideHistoryReader          = (*RideRepository)(nil)
	_ domain.RecentPassengerRidesReader = (*RideRepository)(nil)
)

func (repository *RideRepository) DriverTrips(
	ctx context.Context,
	driverID int,
	history domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	dbDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return nil, err
	}
	limit, err := toPostgresPaginationValue(history.Limit+1, "trip history limit")
	if err != nil {
		return nil, err
	}
	offset, err := toPostgresPaginationValue(history.Offset, "trip history offset")
	if err != nil {
		return nil, err
	}
	items, err := repository.queries.ListDriverRides(ctx, databasepostgres.ListDriverRidesParams{
		DriverID:   pgtype.Int4{Int32: dbDriverID, Valid: true},
		ActiveOnly: history.ActiveOnly,
		Offset:     offset,
		Limit:      limit,
	})
	if err != nil {
		return nil, fmt.Errorf("list driver rides: %w", err)
	}

	result := make([]domain.Ride, 0, len(items))
	for _, item := range items {
		ride, mappingErr := fromPostgresDriverRide(item)
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, ride)
	}
	return result, nil
}

func (repository *RideRepository) PassengerRides(
	ctx context.Context,
	passengerID int,
	history domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	dbPassengerID, err := toPostgresRideID(passengerID, "passenger id")
	if err != nil {
		return nil, err
	}
	limit, err := toPostgresPaginationValue(history.Limit+1, "trip history limit")
	if err != nil {
		return nil, err
	}
	offset, err := toPostgresPaginationValue(history.Offset, "trip history offset")
	if err != nil {
		return nil, err
	}
	items, err := repository.queries.ListPassengerRides(ctx, databasepostgres.ListPassengerRidesParams{
		PassengerID: dbPassengerID,
		Offset:      offset,
		Limit:       limit,
	})
	if err != nil {
		return nil, fmt.Errorf("list passenger rides: %w", err)
	}

	result := make([]domain.Ride, 0, len(items))
	for _, item := range items {
		ride, mappingErr := fromPostgresPassengerRide(item)
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, ride)
	}
	return result, nil
}

func (repository *RideRepository) PassengerRecentRides(
	ctx context.Context,
	passengerID, limit int,
) ([]domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	dbPassengerID, err := toPostgresRideID(passengerID, "passenger id")
	if err != nil {
		return nil, err
	}
	dbLimit, err := toPostgresPaginationValue(limit, "recent rides limit")
	if err != nil {
		return nil, err
	}
	items, err := repository.queries.ListRecentPassengerRides(ctx, databasepostgres.ListRecentPassengerRidesParams{
		PassengerID: dbPassengerID,
		Limit:       dbLimit,
	})
	if err != nil {
		return nil, fmt.Errorf("list recent passenger rides: %w", err)
	}

	result := make([]domain.Ride, 0, len(items))
	for _, item := range items {
		ride, mappingErr := fromPostgresRecentPassengerRide(item)
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, ride)
	}
	return result, nil
}

func fromPostgresDriverRide(item databasepostgres.ListDriverRidesRow) (domain.Ride, error) {
	ride, err := fromPostgresRide(item.Ride)
	if err != nil {
		return domain.Ride{}, err
	}
	ride.PassengerName = item.PassengerName
	ride.PassengerPhone = item.PassengerPhone
	if item.PassengerRating.Valid {
		ride.PassengerRating = item.PassengerRating.Float64
	}
	if item.PassengerFeedback.Valid {
		ride.PassengerFeedback = strings.TrimSpace(item.PassengerFeedback.String)
	}
	return ride, nil
}

func fromPostgresPassengerRide(item databasepostgres.ListPassengerRidesRow) (domain.Ride, error) {
	return fromPostgresRideWithDriverProfile(
		item.Ride,
		item.DriverProfileName,
		item.DriverProfileVehicleType,
		item.DriverProfilePlateNumber,
	)
}

func fromPostgresRecentPassengerRide(item databasepostgres.ListRecentPassengerRidesRow) (domain.Ride, error) {
	return fromPostgresRideWithDriverProfile(
		item.Ride,
		item.DriverProfileName,
		item.DriverProfileVehicleType,
		item.DriverProfilePlateNumber,
	)
}

func fromPostgresRideWithDriverProfile(
	item databasepostgres.Ride,
	driverName, vehicleType, plateNumber string,
) (domain.Ride, error) {
	ride, err := fromPostgresRide(item)
	if err != nil {
		return domain.Ride{}, err
	}
	if ride.DriverName == "" {
		ride.DriverName = driverName
	}
	if ride.VehicleType == "" {
		ride.VehicleType = vehicleType
	}
	if ride.PlateNumber == "" {
		ride.PlateNumber = plateNumber
	}
	return ride, nil
}

func toPostgresPaginationValue(value int, field string) (int32, error) {
	if value < 0 || int64(value) > int64(^uint32(0)>>1) {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}
