package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

const maxPostgresRideID = 1<<31 - 1

// PostgresRideRepository gradually moves ride persistence to generated
// PostgreSQL queries. The embedded repository preserves the existing domain
// surface for operations that have not migrated yet.
type PostgresRideRepository struct {
	*RideRepository
	pool    *pgxpool.Pool
	queries *databasepostgres.Queries
}

var (
	_ domain.Repository = (*PostgresRideRepository)(nil)
	_ interface {
		ActiveRidesForDriver(context.Context, int) ([]domain.Ride, error)
	} = (*PostgresRideRepository)(nil)
)

func NewPostgresRideRepository(
	client *ent.Client,
	pool *pgxpool.Pool,
	platformCommissionBPS int64,
) (*PostgresRideRepository, error) {
	if client == nil {
		return nil, errors.New("ent client is required for the compatibility ride repository")
	}
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &PostgresRideRepository{
		RideRepository: NewRideRepository(client, platformCommissionBPS),
		pool:           pool,
		queries:        databasepostgres.New(pool),
	}, nil
}

func (repository *PostgresRideRepository) Get(ctx context.Context, id int) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	postgresID, err := toPostgresRideID(id, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	item, err := repository.queries.GetRideByID(ctx, postgresID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("find ride: %w", err)
	}
	ride, err := fromPostgresRide(item)
	if err != nil {
		return domain.Ride{}, err
	}
	if ride.DriverID == nil {
		return ride, nil
	}

	driverProfile, err := repository.queries.GetDriverProfileByUserID(ctx, int32(*ride.DriverID))
	if errors.Is(err, pgx.ErrNoRows) {
		return ride, nil
	}
	if err != nil {
		return domain.Ride{}, fmt.Errorf("find ride driver profile: %w", err)
	}
	if ride.DriverName == "" {
		ride.DriverName = driverProfile.Name
	}
	if ride.VehicleType == "" {
		ride.VehicleType = driverProfile.VehicleType
	}
	if ride.PlateNumber == "" {
		ride.PlateNumber = driverProfile.PlateNumber
	}
	return ride, nil
}

func (repository *PostgresRideRepository) ActiveRidesForDriver(ctx context.Context, driverID int) ([]domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return nil, err
	}
	postgresDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return nil, err
	}
	items, err := repository.queries.ListActiveRidesForDriver(ctx, pgtype.Int4{Int32: postgresDriverID, Valid: true})
	if err != nil {
		return nil, fmt.Errorf("list active driver rides: %w", err)
	}
	result := make([]domain.Ride, 0, len(items))
	for _, item := range items {
		ride, mappingErr := fromPostgresRide(item)
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, ride)
	}
	return result, nil
}

func (repository *PostgresRideRepository) validateNativeReadRepository() error {
	if repository == nil || repository.pool == nil || repository.queries == nil {
		return errors.New("postgresql ride read repository is not initialized")
	}
	return nil
}

func fromPostgresRide(item databasepostgres.Ride) (domain.Ride, error) {
	if !item.CreatedAt.Valid {
		return domain.Ride{}, errors.New("ride creation time is null")
	}
	var driverID *int
	if item.DriverID.Valid && item.DriverID.Int32 > 0 {
		value := int(item.DriverID.Int32)
		driverID = &value
	}
	var commissionBPS *int64
	if item.CommissionBps.Valid {
		value := item.CommissionBps.Int64
		commissionBPS = &value
	}
	return domain.Ride{
		ID:                   int(item.ID),
		PassengerID:          int(item.PassengerID),
		DriverID:             driverID,
		Status:               item.Status,
		FareCentavos:         item.FareCentavos,
		RideType:             item.RideType,
		PickupLatitude:       postgresRideFloatValue(item.PickupLatitude),
		PickupLongitude:      postgresRideFloatValue(item.PickupLongitude),
		PickupName:           postgresRideTextValue(item.PickupName),
		DropoffLatitude:      postgresRideFloatValue(item.DropoffLatitude),
		DropoffLongitude:     postgresRideFloatValue(item.DropoffLongitude),
		DropoffName:          postgresRideTextValue(item.DropoffName),
		DistanceKm:           postgresRideFloatValue(item.DistanceKm),
		DurationMinutes:      postgresRideFloatValue(item.DurationMinutes),
		DriverName:           postgresRideTextValue(item.DriverName),
		VehicleType:          postgresRideTextValue(item.VehicleType),
		PlateNumber:          postgresRideTextValue(item.PlateNumber),
		DriverRating:         postgresRideFloatValue(item.DriverRating),
		CreatedAt:            postgresRideTimestamp(item.CreatedAt),
		CompletedAt:          postgresRideTimestamp(item.CompletedAt),
		PaymentStatus:        item.PaymentStatus,
		CommissionBPS:        commissionBPS,
		CommissionCentavos:   item.CommissionCentavos,
		DriverPayoutCentavos: item.DriverPayoutCentavos,
	}, nil
}

func postgresRideTimestamp(value pgtype.Timestamptz) *string {
	if !value.Valid {
		return nil
	}
	formatted := value.Time.UTC().Format(time.RFC3339)
	return &formatted
}

func postgresRideTextValue(value pgtype.Text) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

func postgresRideFloatValue(value pgtype.Float8) float64 {
	if !value.Valid {
		return 0
	}
	return value.Float64
}

func toPostgresRideID(value int, field string) (int32, error) {
	if value <= 0 || int64(value) > int64(maxPostgresRideID) {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}
