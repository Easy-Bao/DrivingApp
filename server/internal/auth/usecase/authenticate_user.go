package usecase

import (
	"context"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

type AuthenticateService struct {
	repository domain.UserRepository
	tokens     domain.TokenIssuer
}

func NewAuthenticateService(repository domain.UserRepository, tokens domain.TokenIssuer) *AuthenticateService {
	return &AuthenticateService{repository: repository, tokens: tokens}
}

func (service *AuthenticateService) Execute(ctx context.Context, email, password string) (domain.User, string, error) {
	account, err := service.repository.FindByEmail(ctx, email)
	if err != nil || account.PasswordHash != HashPassword(password) {
		return domain.User{}, "", domain.ErrInvalidCredentials
	}
	token, err := service.tokens.Issue(strconv.Itoa(account.ID))
	return account, token, err
}
