package app

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

type AuthenticateService struct {
	repository   UserStore
	tokens       TokenIssuer
	sessions     SessionStore
	logger       *slog.Logger
	hashPassword func(string) (string, error)
}

type AuthenticateDependencies struct {
	Repository   UserStore
	Tokens       TokenIssuer
	Sessions     SessionStore
	HashPassword func(string) (string, error)
}

func NewAuthenticateService(dependencies AuthenticateDependencies) *AuthenticateService {
	hashPassword := dependencies.HashPassword
	if hashPassword == nil {
		hashPassword = security.HashPassword
	}
	return &AuthenticateService{
		repository:   dependencies.Repository,
		tokens:       dependencies.Tokens,
		sessions:     dependencies.Sessions,
		logger:       slog.Default(),
		hashPassword: hashPassword,
	}
}

func (service *AuthenticateService) WithLogger(logger *slog.Logger) *AuthenticateService {
	if logger != nil {
		service.logger = logger
	}
	return service
}

func (service *AuthenticateService) Execute(ctx context.Context, email, password string) (domain.User, string, error) {
	account, tokens, err := service.execute(ctx, email, password, "")
	return account, tokens.AccessToken, err
}

func (service *AuthenticateService) ExecuteAs(
	ctx context.Context,
	email string,
	password string,
	role domain.Role,
) (domain.User, string, error) {
	account, tokens, err := service.execute(ctx, email, password, role)
	return account, tokens.AccessToken, err
}

func (service *AuthenticateService) ExecuteSession(
	ctx context.Context,
	email string,
	password string,
) (domain.User, SessionTokens, error) {
	return service.execute(ctx, email, password, "")
}

func (service *AuthenticateService) ExecuteSessionAs(
	ctx context.Context,
	email string,
	password string,
	role domain.Role,
) (domain.User, SessionTokens, error) {
	return service.execute(ctx, email, password, role)
}

func (service *AuthenticateService) execute(
	ctx context.Context,
	email string,
	password string,
	role domain.Role,
) (domain.User, SessionTokens, error) {
	if service == nil || service.repository == nil {
		return domain.User{}, SessionTokens{}, domain.ErrInvalidCredentials
	}
	email = strings.ToLower(strings.TrimSpace(email))
	account, err := service.repository.FindByEmail(ctx, email)
	if err != nil {
		if !errors.Is(err, domain.ErrUserNotFound) {
			service.log().WarnContext(ctx, "find account for authentication failed", "error", err)
		}
		return domain.User{}, SessionTokens{}, domain.ErrInvalidCredentials
	}
	if !security.VerifyPassword(account.PasswordHash, password) {
		return domain.User{}, SessionTokens{}, domain.ErrInvalidCredentials
	}
	if role != "" && account.Role != role {
		return domain.User{}, SessionTokens{}, domain.ErrInvalidCredentials
	}
	if account.AccountStatus != "" && account.AccountStatus != "active" {
		return domain.User{}, SessionTokens{}, domain.ErrAccountSuspended
	}
	if security.IsLegacyPasswordHash(account.PasswordHash) {
		upgradedHash, hashErr := service.hashPassword(password)
		if hashErr != nil {
			service.log().WarnContext(ctx, "upgrade legacy password hash failed", "error", hashErr)
		} else if err := service.repository.UpdatePassword(ctx, account.ID, upgradedHash); err != nil {
			service.log().WarnContext(ctx, "persist upgraded password hash failed", "error", err)
		}
	}
	tokens, err := IssueSessionTokens(
		ctx,
		service.sessions,
		service.tokens,
		strconv.Itoa(account.ID),
		account.Role,
	)
	if err != nil {
		return domain.User{}, SessionTokens{}, fmt.Errorf("issue authentication session: %w", err)
	}
	return account, tokens, nil
}

func (service *AuthenticateService) Refresh(ctx context.Context, rawToken string) (SessionTokens, error) {
	if service == nil || service.sessions == nil || service.repository == nil {
		return SessionTokens{}, domain.ErrRefreshSessionUnavailable
	}
	rawToken = strings.TrimSpace(rawToken)
	if !ValidRefreshToken(rawToken) {
		return SessionTokens{}, domain.ErrInvalidRefreshToken
	}
	now := time.Now().UTC()
	current, err := service.sessions.FindActive(ctx, HashRefreshToken(rawToken), now)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidRefreshToken) {
			return SessionTokens{}, domain.ErrInvalidRefreshToken
		}
		return SessionTokens{}, UnavailableError(err)
	}
	account, err := service.repository.FindByID(ctx, current.UserID)
	if err != nil {
		return SessionTokens{}, UnavailableError(err)
	}
	if account.ID != current.UserID {
		return SessionTokens{}, domain.ErrInvalidRefreshToken
	}
	if account.AccountStatus != "" && account.AccountStatus != "active" {
		return SessionTokens{}, domain.ErrAccountSuspended
	}

	accessToken, err := IssueToken(service.tokens, strconv.Itoa(account.ID), account.Role)
	if err != nil {
		return SessionTokens{}, fmt.Errorf("issue refreshed access token: %w", err)
	}
	replacementToken, replacement, err := ReplacementRefreshSession(account.ID, now)
	if err != nil {
		return SessionTokens{}, fmt.Errorf("create replacement refresh session: %w", err)
	}
	if err := service.sessions.Rotate(
		ctx,
		current.TokenHash,
		replacement,
		now,
	); err != nil {
		if errors.Is(err, domain.ErrInvalidRefreshToken) {
			return SessionTokens{}, domain.ErrInvalidRefreshToken
		}
		return SessionTokens{}, UnavailableError(err)
	}
	return SessionTokens{AccessToken: accessToken, RefreshToken: replacementToken}, nil
}

func (service *AuthenticateService) Logout(ctx context.Context, rawToken string) error {
	if service == nil || service.sessions == nil {
		return domain.ErrRefreshSessionUnavailable
	}
	rawToken = strings.TrimSpace(rawToken)
	if !ValidRefreshToken(rawToken) {
		return domain.ErrInvalidRefreshToken
	}
	if err := service.sessions.Revoke(ctx, HashRefreshToken(rawToken), time.Now().UTC()); err != nil {
		return UnavailableError(err)
	}
	return nil
}

func (service *AuthenticateService) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}
