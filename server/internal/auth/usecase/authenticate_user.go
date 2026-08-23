package usecase

import (
	"context"
	"strconv"
	"strings"

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
	account, tokens, err := service.execute(ctx, email, password, "")
	return account, tokens.AccessToken, err
}

func (service *AuthenticateService) ExecuteAs(ctx context.Context, email, password string, role domain.Role) (domain.User, string, error) {
	account, tokens, err := service.execute(ctx, email, password, role)
	return account, tokens.AccessToken, err
}

func (service *AuthenticateService) ExecuteSession(ctx context.Context, email, password string) (domain.User, SessionTokens, error) {
	return service.execute(ctx, email, password, "")
}

func (service *AuthenticateService) ExecuteSessionAs(ctx context.Context, email, password string, role domain.Role) (domain.User, SessionTokens, error) {
	return service.execute(ctx, email, password, role)
}

func (service *AuthenticateService) execute(ctx context.Context, email, password string, role domain.Role) (domain.User, SessionTokens, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	account, err := service.repository.FindByEmail(ctx, email)
	if err != nil || !VerifyPassword(account.PasswordHash, password) {
		return domain.User{}, SessionTokens{}, domain.ErrInvalidCredentials
	}
	if role != "" && account.Role != role {
		return domain.User{}, SessionTokens{}, domain.ErrInvalidCredentials
	}
	if IsLegacyPasswordHash(account.PasswordHash) {
		if upgradedHash, hashErr := HashPasswordWithError(password); hashErr == nil {
			_ = service.repository.UpdatePassword(ctx, account.ID, upgradedHash)
		}
	}
	tokens, err := issueSessionTokens(service.tokens, strconv.Itoa(account.ID), account.Role)
	return account, tokens, err
}

func (service *AuthenticateService) Refresh(rawToken string) (SessionTokens, error) {
	identity, err := verifyRefreshToken(service.tokens, strings.TrimSpace(rawToken))
	if err != nil {
		return SessionTokens{}, err
	}
	return issueSessionTokens(service.tokens, identity.Subject, domain.Role(identity.Role))
}
