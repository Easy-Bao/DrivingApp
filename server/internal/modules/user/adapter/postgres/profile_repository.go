package postgres

import (
	"context"
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
	"strings"
	"time"
)

type ProfileRepository struct {
	pool                       *pgxpool.Pool
	queries                    *databasepostgres.Queries
	avatarStorage              platformstorage.ObjectStore
	allowUnverifiedTestDrivers bool
	logger                     *slog.Logger
}

var (
	_ app.ProfileStore      = (*ProfileRepository)(nil)
	_ app.AvatarStore       = (*ProfileRepository)(nil)
	_ app.NotificationStore = (*ProfileRepository)(nil)
)

type ProfileRepositoryDependencies struct {
	Pool                       *pgxpool.Pool
	AvatarStorage              platformstorage.ObjectStore
	AllowUnverifiedTestDrivers bool
}

func NewProfileRepository(dependencies ProfileRepositoryDependencies) (*ProfileRepository, error) {
	if dependencies.Pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &ProfileRepository{
		pool:                       dependencies.Pool,
		queries:                    databasepostgres.New(dependencies.Pool),
		avatarStorage:              dependencies.AvatarStorage,
		allowUnverifiedTestDrivers: dependencies.AllowUnverifiedTestDrivers,
		logger:                     slog.Default(),
	}, nil
}

func (repository *ProfileRepository) WithLogger(logger *slog.Logger) *ProfileRepository {
	if repository != nil && logger != nil {
		repository.logger = logger
	}
	return repository
}

func (repository *ProfileRepository) log() *slog.Logger {
	if repository != nil && repository.logger != nil {
		return repository.logger
	}
	return slog.Default()
}

func (repository *ProfileRepository) Get(ctx context.Context, userID int) (domain.Profile, error) {
	if err := repository.validate(); err != nil {
		return domain.Profile{}, fmt.Errorf("validate profile repository: %w", err)
	}
	dbUserID, err := pgutil.ToPositiveInt32(userID, "user id")
	if err != nil {
		return domain.Profile{}, fmt.Errorf("convert profile user id: %w", err)
	}

	account, err := repository.queries.GetUserByID(ctx, dbUserID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.Profile{}, domain.ErrProfileNotFound
		}
		return domain.Profile{}, fmt.Errorf("find profile account: %w", err)
	}

	switch account.Role {
	case "driver":
		driverProfile, driverErr := repository.queries.GetDriverProfileByUserIDFull(ctx, dbUserID)
		if driverErr != nil {
			if errors.Is(driverErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("find driver profile: %w", driverErr)
		}
		return driverProfileFromFullRow(account, driverProfile), nil
	case "passenger":
		passengerProfile, passengerErr := repository.queries.GetPassengerProfileByUserIDFull(ctx, dbUserID)
		if passengerErr != nil {
			if errors.Is(passengerErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("find passenger profile: %w", passengerErr)
		}
		return passengerProfileFromPostgres(account, passengerProfile), nil
	default:
		return domain.Profile{}, domain.ErrProfileNotFound
	}
}

const defaultDriverPresenceMaxAge = 45 * time.Second

func (repository *ProfileRepository) IsDriverOnline(
	ctx context.Context,
	userID int,
	maxAge time.Duration,
) (bool, error) {
	if err := repository.validate(); err != nil {
		return false, fmt.Errorf("validate profile repository: %w", err)
	}
	dbUserID, err := pgutil.ToPositiveInt32(userID, "user id")
	if err != nil {
		return false, fmt.Errorf("convert driver user id: %w", err)
	}
	presence, err := repository.queries.GetDriverOnlinePresence(ctx, dbUserID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		return false, fmt.Errorf("load driver online presence: %w", err)
	}
	return isDriverPresenceFresh(presence.IsOnline, presence.OnlineLastSeenAt, time.Now().UTC(), maxAge), nil
}

func isDriverPresenceFresh(
	isOnline bool,
	lastSeen pgtype.Timestamptz,
	now time.Time,
	maxAge time.Duration,
) bool {
	if !isOnline || !lastSeen.Valid {
		return false
	}
	if maxAge <= 0 {
		maxAge = defaultDriverPresenceMaxAge
	}
	return now.Sub(lastSeen.Time.UTC()) <= maxAge
}

func (repository *ProfileRepository) Save(ctx context.Context, profile domain.Profile) (domain.Profile, error) {
	if err := repository.validate(); err != nil {
		return domain.Profile{}, fmt.Errorf("validate profile repository: %w", err)
	}
	if profile.Role != "driver" && profile.Role != "passenger" {
		return domain.Profile{}, fmt.Errorf("%w: unsupported profile role %q", domain.ErrInvalidRole, profile.Role)
	}
	dbUserID, err := pgutil.ToPositiveInt32(profile.UserID, "user id")
	if err != nil {
		return domain.Profile{}, fmt.Errorf("convert profile user id: %w", err)
	}
	dbProfileID, err := pgutil.ToPositiveInt32(profile.ID, "profile id")
	if err != nil {
		return domain.Profile{}, fmt.Errorf("convert profile id: %w", err)
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("begin profile update transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	account, err := transactionQueries.UpdateUserProfile(ctx, databasepostgres.UpdateUserProfileParams{
		ID:   dbUserID,
		Name: pgutil.ToText(profile.Name),
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.Profile{}, domain.ErrProfileNotFound
		}
		return domain.Profile{}, fmt.Errorf("update profile account: %w", err)
	}

	var updated domain.Profile
	switch profile.Role {
	case "driver":
		currentDriver, lockErr := transactionQueries.LockDriverProfileByUserID(ctx, dbUserID)
		if lockErr != nil {
			if errors.Is(lockErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("lock driver profile: %w", lockErr)
		}
		if currentDriver.IsOnline &&
			(currentDriver.VehicleType != profile.VehicleType ||
				currentDriver.PlateNumber != profile.PlateNumber) {
			return domain.Profile{}, domain.ErrDriverVehicleChangeWhileOnline
		}
		driverProfile, updateErr := transactionQueries.UpdateDriverProfile(ctx, databasepostgres.UpdateDriverProfileParams{
			ID:          dbProfileID,
			UserID:      dbUserID,
			Name:        profile.Name,
			VehicleType: profile.VehicleType,
			PlateNumber: profile.PlateNumber,
		})
		if updateErr != nil {
			if errors.Is(updateErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("update driver profile: %w", updateErr)
		}
		updated = driverProfileFromUpdateRow(account, driverProfile)
	case "passenger":
		if _, lockErr := transactionQueries.LockPassengerProfileByUserID(ctx, dbUserID); lockErr != nil {
			if errors.Is(lockErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("lock passenger profile: %w", lockErr)
		}
		passengerProfile, updateErr := transactionQueries.UpdatePassengerProfile(
			ctx,
			databasepostgres.UpdatePassengerProfileParams{
				ID:      dbProfileID,
				UserID:  dbUserID,
				Name:    profile.Name,
				Address: pgutil.ToText(profile.Address),
				Gender:  profile.Gender,
			},
		)
		if updateErr != nil {
			if errors.Is(updateErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("update passenger profile: %w", updateErr)
		}
		updated = passengerProfileFromPostgres(account, passengerProfile)
	}

	if err := transaction.Commit(ctx); err != nil {
		return domain.Profile{}, fmt.Errorf("commit profile update transaction: %w", err)
	}
	return updated, nil
}

func (repository *ProfileRepository) Patch(
	ctx context.Context,
	userID int,
	patch domain.ProfilePatch,
) (domain.Profile, error) {
	if err := repository.validate(); err != nil {
		return domain.Profile{}, fmt.Errorf("validate profile repository: %w", err)
	}
	dbUserID, err := pgutil.ToPositiveInt32(userID, "user id")
	if err != nil {
		return domain.Profile{}, fmt.Errorf("convert profile user id: %w", err)
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("begin profile patch transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	account, err := transactionQueries.LockUserByID(ctx, dbUserID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.Profile{}, domain.ErrProfileNotFound
		}
		return domain.Profile{}, fmt.Errorf("lock profile account: %w", err)
	}
	if patch.Email != nil && !strings.EqualFold(strings.TrimSpace(*patch.Email), strings.TrimSpace(account.Email)) {
		return domain.Profile{}, domain.ErrEmailChangeNotAllowed
	}
	if patch.Phone != nil && strings.TrimSpace(*patch.Phone) != strings.TrimSpace(account.Phone) {
		return domain.Profile{}, domain.ErrPhoneChangeNotAllowed
	}

	var updated domain.Profile
	switch account.Role {
	case "driver":
		currentDriver, lockErr := transactionQueries.LockDriverProfileByUserID(ctx, dbUserID)
		if lockErr != nil {
			if errors.Is(lockErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("lock driver profile: %w", lockErr)
		}
		name := currentDriver.Name
		if patch.Name != nil {
			name = *patch.Name
		}
		vehicleType := currentDriver.VehicleType
		if patch.VehicleType != nil {
			vehicleType = *patch.VehicleType
		}
		plateNumber := currentDriver.PlateNumber
		if patch.PlateNumber != nil {
			plateNumber = *patch.PlateNumber
		}
		if currentDriver.IsOnline &&
			(currentDriver.VehicleType != vehicleType ||
				currentDriver.PlateNumber != plateNumber) {
			return domain.Profile{}, domain.ErrDriverVehicleChangeWhileOnline
		}
		updatedAccount, userErr := transactionQueries.UpdateUserProfile(ctx, databasepostgres.UpdateUserProfileParams{
			ID:   dbUserID,
			Name: pgutil.ToText(name),
		})
		if userErr != nil {
			if errors.Is(userErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("update profile account: %w", userErr)
		}
		driverProfile, updateErr := transactionQueries.UpdateDriverProfile(ctx, databasepostgres.UpdateDriverProfileParams{
			ID:          currentDriver.ID,
			UserID:      dbUserID,
			Name:        name,
			VehicleType: vehicleType,
			PlateNumber: plateNumber,
		})
		if updateErr != nil {
			if errors.Is(updateErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("update driver profile: %w", updateErr)
		}
		updated = driverProfileFromUpdateRow(updatedAccount, driverProfile)
	case "passenger":
		currentPassenger, lockErr := transactionQueries.LockPassengerProfileByUserID(ctx, dbUserID)
		if lockErr != nil {
			if errors.Is(lockErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("lock passenger profile: %w", lockErr)
		}
		name := currentPassenger.Name
		if patch.Name != nil {
			name = *patch.Name
		}
		address := pgutil.TextValue(currentPassenger.Address)
		if patch.Address != nil {
			address = *patch.Address
		}
		gender := currentPassenger.Gender
		if patch.Gender != nil {
			gender = *patch.Gender
		}
		updatedAccount, userErr := transactionQueries.UpdateUserProfile(ctx, databasepostgres.UpdateUserProfileParams{
			ID:   dbUserID,
			Name: pgutil.ToText(name),
		})
		if userErr != nil {
			if errors.Is(userErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("update profile account: %w", userErr)
		}
		passengerProfile, updateErr := transactionQueries.UpdatePassengerProfile(
			ctx,
			databasepostgres.UpdatePassengerProfileParams{
				ID:      currentPassenger.ID,
				UserID:  dbUserID,
				Name:    name,
				Address: pgutil.ToText(address),
				Gender:  gender,
			},
		)
		if updateErr != nil {
			if errors.Is(updateErr, pgx.ErrNoRows) {
				return domain.Profile{}, domain.ErrProfileNotFound
			}
			return domain.Profile{}, fmt.Errorf("update passenger profile: %w", updateErr)
		}
		updated = passengerProfileFromPostgres(updatedAccount, passengerProfile)
	default:
		return domain.Profile{}, fmt.Errorf("%w: unsupported profile role %q", domain.ErrInvalidRole, account.Role)
	}

	if err := transaction.Commit(ctx); err != nil {
		return domain.Profile{}, fmt.Errorf("commit profile patch transaction: %w", err)
	}
	return updated, nil
}

func (repository *ProfileRepository) UpdateOnlineStatus(
	ctx context.Context,
	userID int,
	targetID int,
	isOnline bool,
) (domain.Profile, error) {
	if err := repository.validate(); err != nil {
		return domain.Profile{}, fmt.Errorf("validate profile repository: %w", err)
	}
	dbUserID, err := pgutil.ToPositiveInt32(userID, "user id")
	if err != nil {
		return domain.Profile{}, fmt.Errorf("convert profile user id: %w", err)
	}
	dbTargetID, err := pgutil.ToPositiveInt32(targetID, "target id")
	if err != nil {
		return domain.Profile{}, fmt.Errorf("convert profile target id: %w", err)
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("begin driver online status transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	lockedProfile, err := transactionQueries.LockDriverProfileForOnlineStatus(
		ctx,
		databasepostgres.LockDriverProfileForOnlineStatusParams{
			UserID:   dbUserID,
			TargetID: dbTargetID,
		},
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.Profile{}, domain.ErrProfileNotFound
		}
		return domain.Profile{}, fmt.Errorf("lock driver online status profile: %w", err)
	}
	if !isOnline {
		activeRideCount, countErr := transactionQueries.CountActiveRidesForDriver(
			ctx,
			pgtype.Int4{Int32: lockedProfile.UserID, Valid: true},
		)
		if countErr != nil {
			return domain.Profile{}, fmt.Errorf("count active driver rides: %w", countErr)
		}
		if activeRideCount > 0 {
			return domain.Profile{}, domain.ErrDriverAvailabilityBlocked
		}
	}

	profile, err := transactionQueries.UpdateDriverOnlineStatus(
		ctx,
		databasepostgres.UpdateDriverOnlineStatusParams{
			UserID:                     dbUserID,
			IsOnline:                   isOnline,
			TargetID:                   dbTargetID,
			AllowUnverifiedTestDrivers: repository.allowUnverifiedTestDrivers,
		},
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.Profile{}, domain.ErrProfileNotFound
		}
		return domain.Profile{}, fmt.Errorf("update driver online status: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Profile{}, fmt.Errorf("commit driver online status transaction: %w", err)
	}
	return domain.Profile{
		ID:               int(profile.ID),
		UserID:           int(profile.UserID),
		Role:             "driver",
		IsOnline:         profile.IsOnline,
		OnlineLastSeenAt: onlineLastSeenAt(profile.OnlineLastSeenAt),
	}, nil
}

func (repository *ProfileRepository) validate() error {
	if repository == nil {
		return errors.New("postgresql profile repository is not initialized")
	}
	if repository.pool == nil || repository.queries == nil {
		return errors.New("postgresql profile repository is not initialized")
	}
	return nil
}
