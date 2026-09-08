package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	minPostgresUserID = -1 << 31
	maxPostgresUserID = 1<<31 - 1
)

// PostgresUserRepository persists authentication accounts through the generated
// PostgreSQL queries. The existing UserRepository remains available while the
// rest of the server moves off Ent incrementally.
type PostgresUserRepository struct {
	pool    *pgxpool.Pool
	queries *databasepostgres.Queries
}

var _ domain.VerifiedUserRepository = (*PostgresUserRepository)(nil)

func NewPostgresUserRepository(pool *pgxpool.Pool) (*PostgresUserRepository, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &PostgresUserRepository{
		pool:    pool,
		queries: databasepostgres.New(pool),
	}, nil
}

func (repository *PostgresUserRepository) Create(ctx context.Context, account domain.User) (domain.User, error) {
	if err := repository.validate(); err != nil {
		return domain.User{}, err
	}
	if err := validatePostgresUserRole(account.Role); err != nil {
		return domain.User{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.User{}, fmt.Errorf("begin user creation transaction: %w", err)
	}
	defer func() {
		_ = transaction.Rollback(ctx)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	created, err := transactionQueries.CreateUser(ctx, databasepostgres.CreateUserParams{
		Name:         toPostgresText(account.Name),
		Phone:        account.Phone,
		Email:        account.Email,
		PasswordHash: account.PasswordHash,
		Role:         string(account.Role),
		IsVerified:   account.IsVerified,
	})
	if err != nil {
		if isPostgresUniqueViolation(err) {
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
		preferredRideType := account.PreferredRideType
		if preferredRideType == "" {
			preferredRideType = "solo-ride"
		}
		err = transactionQueries.CreatePassengerProfile(ctx, databasepostgres.CreatePassengerProfileParams{
			UserID:            created.ID,
			Name:              account.Name,
			PreferredRideType: toPostgresText(preferredRideType),
		})
	}
	if err != nil {
		return domain.User{}, fmt.Errorf("create %s profile: %w", account.Role, err)
	}

	if err := transaction.Commit(ctx); err != nil {
		return domain.User{}, fmt.Errorf("commit user creation transaction: %w", err)
	}

	result := fromPostgresUser(created)
	result.Name = account.Name
	result.VehicleType = account.VehicleType
	result.PlateNumber = account.PlateNumber
	result.PreferredRideType = account.PreferredRideType
	return result, nil
}

func (repository *PostgresUserRepository) MarkVerified(ctx context.Context, id int) error {
	if err := repository.validate(); err != nil {
		return err
	}
	postgresID, err := toPostgresUserID(id)
	if err != nil {
		return err
	}

	rows, err := repository.queries.MarkUserVerified(ctx, postgresID)
	if err != nil {
		return fmt.Errorf("mark user %d verified: %w", id, err)
	}
	if rows == 0 {
		return fmt.Errorf("mark user %d verified: %w", id, pgx.ErrNoRows)
	}
	return nil
}

func (repository *PostgresUserRepository) FindByEmail(ctx context.Context, email string) (domain.User, error) {
	if err := repository.validate(); err != nil {
		return domain.User{}, err
	}
	account, err := repository.queries.GetUserByEmail(ctx, email)
	if err != nil {
		return domain.User{}, fmt.Errorf("find user by email: %w", err)
	}
	return repository.withProfile(ctx, fromPostgresUser(account))
}

func (repository *PostgresUserRepository) FindByID(ctx context.Context, id int) (domain.User, error) {
	if err := repository.validate(); err != nil {
		return domain.User{}, err
	}
	postgresID, err := toPostgresUserID(id)
	if err != nil {
		return domain.User{}, err
	}

	account, err := repository.queries.GetUserByID(ctx, postgresID)
	if err != nil {
		return domain.User{}, fmt.Errorf("find user by id: %w", err)
	}
	return repository.withProfile(ctx, fromPostgresUser(account))
}

func (repository *PostgresUserRepository) UpdatePassword(ctx context.Context, id int, passwordHash string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	postgresID, err := toPostgresUserID(id)
	if err != nil {
		return err
	}

	rows, err := repository.queries.UpdateUserPassword(ctx, databasepostgres.UpdateUserPasswordParams{
		ID:           postgresID,
		PasswordHash: passwordHash,
	})
	if err != nil {
		return fmt.Errorf("update password for user %d: %w", id, err)
	}
	if rows == 0 {
		return fmt.Errorf("update password for user %d: %w", id, pgx.ErrNoRows)
	}
	return nil
}

func (repository *PostgresUserRepository) withProfile(ctx context.Context, account domain.User) (domain.User, error) {
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
		account.PreferredRideType = postgresTextValue(profile.PreferredRideType)
	default:
		return domain.User{}, domain.ErrInvalidRole
	}
	return account, nil
}

func (repository *PostgresUserRepository) validate() error {
	if repository == nil || repository.pool == nil || repository.queries == nil {
		return errors.New("postgresql user repository is not initialized")
	}
	return nil
}

func validatePostgresUserRole(role domain.Role) error {
	switch role {
	case domain.Driver, domain.Passenger:
		return nil
	default:
		return domain.ErrInvalidRole
	}
}

func toPostgresUserID(id int) (int32, error) {
	id64 := int64(id)
	if id64 < minPostgresUserID || id64 > maxPostgresUserID {
		return 0, fmt.Errorf("user id %d is outside PostgreSQL integer range", id)
	}
	return int32(id), nil
}

func fromPostgresUser(account databasepostgres.User) domain.User {
	return domain.User{
		ID:           int(account.ID),
		Email:        account.Email,
		Phone:        account.Phone,
		Name:         postgresTextValue(account.Name),
		Role:         domain.Role(account.Role),
		PasswordHash: account.PasswordHash,
		IsVerified:   account.IsVerified,
	}
}

func toPostgresText(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}

func postgresTextValue(value pgtype.Text) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

func isPostgresUniqueViolation(err error) bool {
	var postgresError *pgconn.PgError
	return errors.As(err, &postgresError) && postgresError.Code == "23505"
}
