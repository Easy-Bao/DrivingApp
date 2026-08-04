package postgres

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/passengerprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/user"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

type UserRepository struct{ client *ent.Client }

func NewUserRepository(client *ent.Client) *UserRepository { return &UserRepository{client: client} }

func (repository *UserRepository) Create(ctx context.Context, account domain.User) (domain.User, error) {
	created, err := repository.client.User.Create().SetName(account.Name).SetEmail(account.Email).SetPhone(account.Phone).SetRole(string(account.Role)).SetPasswordHash(account.PasswordHash).SetIsVerified(account.IsVerified).Save(ctx)
	if err != nil {
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

func (repository *UserRepository) Provision(ctx context.Context, account domain.User) error {
	switch account.Role {
	case domain.Driver:
		_, err := repository.client.DriverProfile.Create().SetUserID(account.ID).SetName(account.Name).SetVehicleType(account.VehicleType).SetPlateNumber(account.PlateNumber).Save(ctx)
		return err
	case domain.Passenger:
		preferredRideType := account.PreferredRideType
		if preferredRideType == "" {
			preferredRideType = "solo-ride"
		}
		_, err := repository.client.PassengerProfile.Create().SetUserID(account.ID).SetName(account.Name).SetPreferredRideType(preferredRideType).Save(ctx)
		return err
	default:
		return domain.ErrInvalidRole
	}
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
		if err == nil {
			account.Name = profile.Name
			account.VehicleType = profile.VehicleType
			account.PlateNumber = profile.PlateNumber
		}
	case domain.Passenger:
		profile, err := repository.client.PassengerProfile.Query().Where(passengerprofile.UserIDEQ(account.ID)).Only(ctx)
		if err == nil {
			account.Name = profile.Name
			account.PreferredRideType = profile.PreferredRideType
		}
	}
	return account, nil
}
