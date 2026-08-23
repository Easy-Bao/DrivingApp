package postgres

import (
	"context"
	"database/sql"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/passengerprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/user"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

type UserRepository struct{ client *ent.Client }

func NewUserRepository(client *ent.Client) *UserRepository { return &UserRepository{client: client} }

func (repository *UserRepository) Create(ctx context.Context, account domain.User) (domain.User, error) {
	transaction, err := repository.client.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return domain.User{}, err
	}
	defer transaction.Rollback()

	created, err := transaction.User.Create().SetName(account.Name).SetEmail(account.Email).SetPhone(account.Phone).SetRole(string(account.Role)).SetPasswordHash(account.PasswordHash).SetIsVerified(account.IsVerified).Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			return domain.User{}, domain.ErrAccountConflict
		}
		return domain.User{}, err
	}
	switch account.Role {
	case domain.Driver:
		_, err = transaction.DriverProfile.Create().SetUserID(created.ID).SetName(account.Name).SetVehicleType(account.VehicleType).SetPlateNumber(account.PlateNumber).Save(ctx)
	case domain.Passenger:
		preferredRideType := account.PreferredRideType
		if preferredRideType == "" {
			preferredRideType = "solo-ride"
		}
		_, err = transaction.PassengerProfile.Create().SetUserID(created.ID).SetName(account.Name).SetPreferredRideType(preferredRideType).Save(ctx)
	default:
		return domain.User{}, domain.ErrInvalidRole
	}
	if err != nil {
		return domain.User{}, err
	}
	if err := transaction.Commit(); err != nil {
		return domain.User{}, err
	}
	result := fromEnt(created)
	result.Name = account.Name
	result.VehicleType = account.VehicleType
	result.PlateNumber = account.PlateNumber
	result.PreferredRideType = account.PreferredRideType
	return result, nil
}

func (repository *UserRepository) MarkVerified(ctx context.Context, id int) error {
	return repository.client.User.UpdateOneID(id).SetIsVerified(true).Exec(ctx)
}

func (repository *UserRepository) FindByEmail(ctx context.Context, email string) (domain.User, error) {
	account, err := repository.client.User.Query().Where(user.EmailEQ(email)).Only(ctx)
	if err != nil {
		return domain.User{}, err
	}
	return repository.withProfile(ctx, fromEnt(account))
}
func (repository *UserRepository) FindByID(ctx context.Context, id int) (domain.User, error) {
	account, err := repository.client.User.Get(ctx, id)
	if err != nil {
		return domain.User{}, err
	}
	return repository.withProfile(ctx, fromEnt(account))
}
func (repository *UserRepository) UpdatePassword(ctx context.Context, id int, passwordHash string) error {
	return repository.client.User.UpdateOneID(id).SetPasswordHash(passwordHash).Exec(ctx)
}
func fromEnt(account *ent.User) domain.User {
	return domain.User{ID: account.ID, Email: account.Email, Phone: account.Phone, Name: account.Name, Role: domain.Role(account.Role), PasswordHash: account.PasswordHash, IsVerified: account.IsVerified}
}

func (repository *UserRepository) withProfile(ctx context.Context, account domain.User) (domain.User, error) {
	switch account.Role {
	case domain.Driver:
		profile, err := repository.client.DriverProfile.Query().Where(driverprofile.UserIDEQ(account.ID)).Only(ctx)
		if err != nil {
			return domain.User{}, err
		}
		account.Name = profile.Name
		account.VehicleType = profile.VehicleType
		account.PlateNumber = profile.PlateNumber
	case domain.Passenger:
		profile, err := repository.client.PassengerProfile.Query().Where(passengerprofile.UserIDEQ(account.ID)).Only(ctx)
		if err != nil {
			return domain.User{}, err
		}
		account.Name = profile.Name
		account.PreferredRideType = profile.PreferredRideType
	default:
		return domain.User{}, domain.ErrInvalidRole
	}
	return account, nil
}
