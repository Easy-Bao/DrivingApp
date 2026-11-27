package postgres

import (
	"context"
	"errors"
	"fmt"

	authports "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UserRepository struct {
	pool    *pgxpool.Pool
	queries *databasepostgres.Queries
}

var _ authports.VerifiedUserStore = (*UserRepository)(nil)
var _ authports.EmailChangeStore = (*UserRepository)(nil)

func NewUserRepository(pool *pgxpool.Pool) (*UserRepository, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &UserRepository{
		pool:    pool,
		queries: databasepostgres.New(pool),
	}, nil
}

func (repository *UserRepository) Create(ctx context.Context, account domain.User) (domain.User, error) {
	return repository.createAccount(ctx, account, nil)
}

func (repository *UserRepository) CreateWithSession(
	ctx context.Context,
	account domain.User,
	session domain.RefreshSession,
) (domain.User, error) {
	return repository.createAccount(ctx, account, &session)
}

func (repository *UserRepository) createAccount(
	ctx context.Context,
	account domain.User,
	session *domain.RefreshSession,
) (domain.User, error) {
	if err := repository.validate(); err != nil {
		return domain.User{}, fmt.Errorf("validate user repository: %w", err)
	}
	if err := validateUserRole(account.Role); err != nil {
		return domain.User{}, err
	}
	if session != nil && session.TokenHash == "" {
		return domain.User{}, fmt.Errorf("%w: refresh session token hash is required", domain.ErrRefreshSessionUnavailable)
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.User{}, fmt.Errorf("begin user creation transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	created, err := transactionQueries.CreateUser(ctx, databasepostgres.CreateUserParams{
		Name:         pgutil.ToText(account.Name),
		Phone:        account.Phone,
		Email:        account.Email,
		PasswordHash: account.PasswordHash,
		Role:         string(account.Role),
		IsVerified:   account.IsVerified,
	})
	if err != nil {
		if pgutil.IsUniqueViolation(err) {
			return domain.User{}, domain.ErrAccountConflict
		}
		return domain.User{}, fmt.Errorf("create user: %w", err)
	}

	switch account.Role {
	case domain.Driver:
		err = transactionQueries.CreateDriverProfile(ctx, databasepostgres.CreateDriverProfileParams{
			UserID:      created.ID,
			Name:        account.Name,
			VehicleType: account.VehicleType,
			PlateNumber: account.PlateNumber,
		})
	case domain.Passenger:
		err = transactionQueries.CreatePassengerProfile(ctx, databasepostgres.CreatePassengerProfileParams{
			UserID: created.ID,
			Name:   account.Name,
		})
	}
	if err != nil {
		return domain.User{}, fmt.Errorf("create %s profile: %w", account.Role, err)
	}

	if session != nil {
		if err := transactionQueries.CreateRefreshSession(ctx, databasepostgres.CreateRefreshSessionParams{
			UserID:    created.ID,
			TokenHash: session.TokenHash,
			ExpiresAt: pgutil.ToTimestamptz(session.ExpiresAt),
		}); err != nil {
			return domain.User{}, fmt.Errorf("%w: create initial refresh session: %w", domain.ErrRefreshSessionUnavailable, err)
		}
	}

	if err := transaction.Commit(ctx); err != nil {
		return domain.User{}, fmt.Errorf("commit user creation transaction: %w", err)
	}

	result := fromPostgresUser(created)
	result.Name = account.Name
	result.VehicleType = account.VehicleType
	result.PlateNumber = account.PlateNumber
	return result, nil
}

func (repository *UserRepository) MarkVerified(ctx context.Context, userID int) error {
	if err := repository.validate(); err != nil {
		return fmt.Errorf("validate user repository: %w", err)
	}
	dbUserID, err := pgutil.ToInt32(userID, "user id")
	if err != nil {
		return fmt.Errorf("convert user id: %w", err)
	}

	rows, err := repository.queries.MarkUserVerified(ctx, dbUserID)
	if err != nil {
		return fmt.Errorf("mark user %d verified: %w", userID, err)
	}
	if rows == 0 {
		return fmt.Errorf("mark user %d verified: %w", userID, domain.ErrInvalidOTP)
	}
	return nil
}

func (repository *UserRepository) MarkVerifiedWithSession(
	ctx context.Context,
	userID int,
	session domain.RefreshSession,
) error {
	if err := repository.validate(); err != nil {
		return fmt.Errorf("validate user repository: %w", err)
	}
	if session.TokenHash == "" {
		return fmt.Errorf("%w: refresh session token hash is required", domain.ErrRefreshSessionUnavailable)
	}
	dbUserID, err := pgutil.ToInt32(userID, "user id")
	if err != nil {
		return fmt.Errorf("convert user id: %w", err)
	}
	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin verification transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
	}()

	txQueries := repository.queries.WithTx(transaction)
	rows, err := txQueries.MarkUserVerified(ctx, dbUserID)
	if err != nil {
		return fmt.Errorf("mark user %d verified: %w", userID, err)
	}
	if rows == 0 {
		return fmt.Errorf("mark user %d verified: %w", userID, domain.ErrInvalidOTP)
	}
	if err := txQueries.CreateRefreshSession(ctx, databasepostgres.CreateRefreshSessionParams{
		UserID:    dbUserID,
		TokenHash: session.TokenHash,
		ExpiresAt: pgutil.ToTimestamptz(session.ExpiresAt),
	}); err != nil {
		return fmt.Errorf("%w: create verified refresh session: %w", domain.ErrRefreshSessionUnavailable, err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return fmt.Errorf("commit verification transaction: %w", err)
	}
	return nil
}

func (repository *UserRepository) FindByEmail(ctx context.Context, email string) (domain.User, error) {
	if err := repository.validate(); err != nil {
		return domain.User{}, fmt.Errorf("validate user repository: %w", err)
	}
	account, err := repository.queries.GetUserByEmail(ctx, email)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.User{}, domain.ErrUserNotFound
	}
	if err != nil {
		return domain.User{}, fmt.Errorf("find user by email: %w", err)
	}
	profile, err := repository.withProfile(ctx, fromPostgresUser(account))
	if err != nil {
		return domain.User{}, fmt.Errorf("load user profile: %w", err)
	}
	return profile, nil
}

func (repository *UserRepository) FindByID(ctx context.Context, userID int) (domain.User, error) {
	if err := repository.validate(); err != nil {
		return domain.User{}, fmt.Errorf("validate user repository: %w", err)
	}
	dbUserID, err := pgutil.ToInt32(userID, "user id")
	if err != nil {
		return domain.User{}, fmt.Errorf("convert user id: %w", err)
	}

	account, err := repository.queries.GetUserByID(ctx, dbUserID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.User{}, domain.ErrUserNotFound
	}
	if err != nil {
		return domain.User{}, fmt.Errorf("find user by id: %w", err)
	}
	profile, err := repository.withProfile(ctx, fromPostgresUser(account))
	if err != nil {
		return domain.User{}, fmt.Errorf("load user profile: %w", err)
	}
	return profile, nil
}

func (repository *UserRepository) UpdatePassword(ctx context.Context, userID int, passwordHash string) error {
	if err := repository.validate(); err != nil {
		return fmt.Errorf("validate user repository: %w", err)
	}
	dbUserID, err := pgutil.ToInt32(userID, "user id")
	if err != nil {
		return fmt.Errorf("convert user id: %w", err)
	}

	rows, err := repository.queries.UpdateUserPassword(ctx, databasepostgres.UpdateUserPasswordParams{
		ID:           dbUserID,
		PasswordHash: passwordHash,
	})
	if err != nil {
		return fmt.Errorf("update password for user %d: %w", userID, err)
	}
	if rows == 0 {
		return fmt.Errorf("update password for user %d: %w", userID, pgx.ErrNoRows)
	}
	return nil
}

func (repository *UserRepository) UpgradePasswordHash(
	ctx context.Context,
	userID int,
	expectedHash string,
	passwordHash string,
) (bool, error) {
	if err := repository.validate(); err != nil {
		return false, fmt.Errorf("validate user repository: %w", err)
	}
	dbUserID, err := pgutil.ToInt32(userID, "user id")
	if err != nil {
		return false, fmt.Errorf("convert user id: %w", err)
	}
	rows, err := repository.queries.UpgradeUserPasswordHash(ctx, databasepostgres.UpgradeUserPasswordHashParams{
		ID:           dbUserID,
		PasswordHash: passwordHash,
		ExpectedHash: expectedHash,
	})
	if err != nil {
		return false, fmt.Errorf("upgrade password hash for user %d: %w", userID, err)
	}
	return rows > 0, nil
}

func (repository *UserRepository) UpdateEmail(
	ctx context.Context,
	userID int,
	expectedEmail string,
	newEmail string,
) error {
	if err := repository.validate(); err != nil {
		return fmt.Errorf("validate user repository: %w", err)
	}
	dbUserID, err := pgutil.ToInt32(userID, "user id")
	if err != nil {
		return fmt.Errorf("convert user id: %w", err)
	}
	rows, err := repository.queries.UpdateUserEmail(ctx, databasepostgres.UpdateUserEmailParams{
		UserID:        dbUserID,
		ExpectedEmail: expectedEmail,
		NewEmail:      newEmail,
	})
	if err != nil {
		if pgutil.IsUniqueViolation(err) {
			return domain.ErrEmailTaken
		}
		return fmt.Errorf("update email for user %d: %w", userID, err)
	}
	if rows == 0 {
		return domain.ErrEmailChangeStale
	}
	return nil
}

func (repository *UserRepository) withProfile(ctx context.Context, account domain.User) (domain.User, error) {
	switch account.Role {
	case domain.Driver:
		profile, err := repository.queries.GetDriverProfileByUserID(ctx, int32(account.ID))
		if err != nil {
			return domain.User{}, fmt.Errorf("find driver profile for user %d: %w", account.ID, err)
		}
		account.Name = profile.Name
		account.VehicleType = profile.VehicleType
		account.PlateNumber = profile.PlateNumber
	case domain.Passenger:
		profile, err := repository.queries.GetPassengerProfileByUserID(ctx, int32(account.ID))
		if err != nil {
			return domain.User{}, fmt.Errorf("find passenger profile for user %d: %w", account.ID, err)
		}
		account.Name = profile.Name
	default:
		return domain.User{}, domain.ErrInvalidRole
	}
	return account, nil
}

func (repository *UserRepository) validate() error {
	if repository == nil {
		return errors.New("postgresql user repository is not initialized")
	}
	if repository.pool == nil || repository.queries == nil {
		return errors.New("postgresql user repository is not initialized")
	}
	return nil
}

func validateUserRole(role domain.Role) error {
	switch role {
	case domain.Driver, domain.Passenger:
		return nil
	default:
		return domain.ErrInvalidRole
	}
}

func fromPostgresUser(account databasepostgres.User) domain.User {
	return domain.User{
		ID:            int(account.ID),
		Email:         account.Email,
		Phone:         account.Phone,
		Name:          pgutil.TextValue(account.Name),
		Role:          domain.Role(account.Role),
		PasswordHash:  account.PasswordHash,
		IsVerified:    account.IsVerified,
		AccountStatus: account.AccountStatus,
	}
}
