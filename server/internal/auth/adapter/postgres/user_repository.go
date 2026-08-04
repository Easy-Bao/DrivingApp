package postgres

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/user"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

type UserRepository struct{ client *ent.Client }

func NewUserRepository(client *ent.Client) *UserRepository { return &UserRepository{client: client} }

func (repository *UserRepository) Create(ctx context.Context, account domain.User) (domain.User, error) {
	created, err := repository.client.User.Create().SetEmail(account.Email).SetPhone(account.Phone).SetRole(string(account.Role)).SetPasswordHash(account.PasswordHash).SetIsVerified(account.IsVerified).Save(ctx)
	if err != nil {
		return domain.User{}, err
	}
	return fromEnt(created), nil
}

func (repository *UserRepository) FindByEmail(ctx context.Context, email string) (domain.User, error) {
	account, err := repository.client.User.Query().Where(user.EmailEQ(email)).Only(ctx)
	if err != nil {
		return domain.User{}, err
	}
	return fromEnt(account), nil
}
func (repository *UserRepository) FindByID(ctx context.Context, id int) (domain.User, error) {
	account, err := repository.client.User.Get(ctx, id)
	if err != nil {
		return domain.User{}, err
	}
	return fromEnt(account), nil
}
func (repository *UserRepository) UpdatePassword(ctx context.Context, id int, passwordHash string) error {
	return repository.client.User.UpdateOneID(id).SetPasswordHash(passwordHash).Exec(ctx)
}
func fromEnt(account *ent.User) domain.User {
	return domain.User{ID: account.ID, Email: account.Email, Phone: account.Phone, Role: domain.Role(account.Role), PasswordHash: account.PasswordHash, IsVerified: account.IsVerified}
}
