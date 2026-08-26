package usecase

import (
	"context"
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

type AuthenticateService struct {
	repository domain.UserRepository
	tokens     domain.TokenIssuer
	sessions   domain.RefreshSessionStore
}

func NewAuthenticateService(repository domain.UserRepository, tokens domain.TokenIssuer, sessions domain.RefreshSessionStore) *AuthenticateService {
	return &AuthenticateService{repository: repository, tokens: tokens, sessions: sessions}
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
	tokens, err := issueSessionTokens(ctx, service.sessions, service.tokens, strconv.Itoa(account.ID), account.Role)
	return account, tokens, err
}

func (service *AuthenticateService) Refresh(ctx context.Context, rawToken string) (SessionTokens, error) {
	if service.sessions == nil {
		return SessionTokens{}, domain.ErrRefreshSessionUnavailable
	}
	rawToken = strings.TrimSpace(rawToken)
	if rawToken == "" {
		return SessionTokens{}, domain.ErrInvalidRefreshToken
	}
	now := time.Now().UTC()
	current, err := service.sessions.FindActive(ctx, hashRefreshToken(rawToken), now)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidRefreshToken) {
			return SessionTokens{}, domain.ErrInvalidRefreshToken
		}
		return SessionTokens{}, unavailableSessionError(err)
	}
	account, err := service.repository.FindByID(ctx, current.UserID)
	if err != nil {
		return SessionTokens{}, unavailableSessionError(err)
	}
	if account.ID != current.UserID {
		return SessionTokens{}, domain.ErrInvalidRefreshToken
	}

	accessToken, err := issueToken(service.tokens, strconv.Itoa(account.ID), account.Role)
	if err != nil {
		return SessionTokens{}, err
	}
	replacementToken, replacement, err := replacementRefreshSession(account.ID, now)
	if err != nil {
		return SessionTokens{}, err
	}
	if err := service.sessions.Rotate(ctx, current.TokenHash, replacement, now); err != nil {
		if errors.Is(err, domain.ErrInvalidRefreshToken) {
			return SessionTokens{}, domain.ErrInvalidRefreshToken
		}
		return SessionTokens{}, unavailableSessionError(err)
	}
	return SessionTokens{AccessToken: accessToken, RefreshToken: replacementToken}, nil
}

func (service *AuthenticateService) Logout(ctx context.Context, rawToken string) error {
	if service.sessions == nil {
		return domain.ErrRefreshSessionUnavailable
	}
	rawToken = strings.TrimSpace(rawToken)
	if rawToken == "" {
		return domain.ErrInvalidRefreshToken
	}
	if err := service.sessions.Revoke(ctx, hashRefreshToken(rawToken), time.Now().UTC()); err != nil {
		return unavailableSessionError(err)
	}
	return nil
}
