package authentication

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/session"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

type AuthenticateService struct {
	repository authports.UserStore
	tokens     authports.TokenIssuer
	sessions   authports.SessionStore
	logger     *slog.Logger
}

type Dependencies struct {
	Repository authports.UserStore
	Tokens     authports.TokenIssuer
	Sessions   authports.SessionStore
}

func NewAuthenticateService(dependencies Dependencies) *AuthenticateService {
	return &AuthenticateService{
		repository: dependencies.Repository,
		tokens:     dependencies.Tokens,
		sessions:   dependencies.Sessions,
		logger:     slog.Default(),
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
) (domain.User, session.SessionTokens, error) {
	return service.execute(ctx, email, password, "")
}

func (service *AuthenticateService) ExecuteSessionAs(
	ctx context.Context,
	email string,
	password string,
	role domain.Role,
) (domain.User, session.SessionTokens, error) {
	return service.execute(ctx, email, password, role)
}

func (service *AuthenticateService) execute(
	ctx context.Context,
	email string,
	password string,
	role domain.Role,
) (domain.User, session.SessionTokens, error) {
	if service == nil || service.repository == nil {
		return domain.User{}, session.SessionTokens{}, domain.ErrInvalidCredentials
	}
	email = strings.ToLower(strings.TrimSpace(email))
	account, err := service.repository.FindByEmail(ctx, email)
	if err != nil {
		if !errors.Is(err, domain.ErrUserNotFound) {
			service.log().WarnContext(ctx, "find account for authentication failed", "error", err)
		}
		return domain.User{}, session.SessionTokens{}, domain.ErrInvalidCredentials
	}
	if !security.VerifyPassword(account.PasswordHash, password) {
		return domain.User{}, session.SessionTokens{}, domain.ErrInvalidCredentials
	}
	if role != "" && account.Role != role {
		return domain.User{}, session.SessionTokens{}, domain.ErrInvalidCredentials
	}
	if security.IsLegacyPasswordHash(account.PasswordHash) {
		upgradedHash, hashErr := security.HashPassword(password)
		if hashErr != nil {
			service.log().WarnContext(ctx, "upgrade legacy password hash failed", "error", hashErr)
		} else if err := service.repository.UpdatePassword(ctx, account.ID, upgradedHash); err != nil {
			service.log().WarnContext(ctx, "persist upgraded password hash failed", "error", err)
		}
	}
	tokens, err := session.IssueSessionTokens(
		ctx,
		service.sessions,
		service.tokens,
		strconv.Itoa(account.ID),
		account.Role,
	)
	if err != nil {
		return domain.User{}, session.SessionTokens{}, fmt.Errorf("issue authentication session: %w", err)
	}
	return account, tokens, nil
}

func (service *AuthenticateService) Refresh(ctx context.Context, rawToken string) (session.SessionTokens, error) {
	if service == nil || service.sessions == nil || service.repository == nil {
		return session.SessionTokens{}, domain.ErrRefreshSessionUnavailable
	}
	rawToken = strings.TrimSpace(rawToken)
	if !session.ValidRefreshToken(rawToken) {
		return session.SessionTokens{}, domain.ErrInvalidRefreshToken
	}
	now := time.Now().UTC()
	current, err := service.sessions.FindActive(ctx, session.HashRefreshToken(rawToken), now)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidRefreshToken) {
			return session.SessionTokens{}, domain.ErrInvalidRefreshToken
		}
		return session.SessionTokens{}, session.UnavailableError(err)
	}
	account, err := service.repository.FindByID(ctx, current.UserID)
	if err != nil {
		return session.SessionTokens{}, session.UnavailableError(err)
	}
	if account.ID != current.UserID {
		return session.SessionTokens{}, domain.ErrInvalidRefreshToken
	}

	accessToken, err := session.IssueToken(service.tokens, strconv.Itoa(account.ID), account.Role)
	if err != nil {
		return session.SessionTokens{}, fmt.Errorf("issue refreshed access token: %w", err)
	}
	replacementToken, replacement, err := session.ReplacementRefreshSession(account.ID, now)
	if err != nil {
		return session.SessionTokens{}, fmt.Errorf("create replacement refresh session: %w", err)
	}
	if err := service.sessions.Rotate(
		ctx,
		current.TokenHash,
		replacement,
		now,
	); err != nil {
		if errors.Is(err, domain.ErrInvalidRefreshToken) {
			return session.SessionTokens{}, domain.ErrInvalidRefreshToken
		}
		return session.SessionTokens{}, session.UnavailableError(err)
	}
	return session.SessionTokens{AccessToken: accessToken, RefreshToken: replacementToken}, nil
}

func (service *AuthenticateService) Logout(ctx context.Context, rawToken string) error {
	if service == nil || service.sessions == nil {
		return domain.ErrRefreshSessionUnavailable
	}
	rawToken = strings.TrimSpace(rawToken)
	if !session.ValidRefreshToken(rawToken) {
		return domain.ErrInvalidRefreshToken
	}
	if err := service.sessions.Revoke(ctx, session.HashRefreshToken(rawToken), time.Now().UTC()); err != nil {
		return session.UnavailableError(err)
	}
	return nil
}

func (service *AuthenticateService) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}
