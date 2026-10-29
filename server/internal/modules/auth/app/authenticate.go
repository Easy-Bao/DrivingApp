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

const _dummyBcryptHash = "$2a$12$sjZVk/NciE592gulJMkQWOigSaIF6q6HExHI0yRsy.XMYD7ffKW3i"

type AuthenticateService struct {
	repository   UserStore
	tokens       TokenIssuer
	sessions     SessionStore
	logger       *slog.Logger
	hashPassword func(string) (string, error)
	dummyHash    string
}

type AuthenticateDependencies struct {
	Repository   UserStore
	Tokens       TokenIssuer
	Sessions     SessionStore
	HashPassword func(string) (string, error)
	DummyHash    string
}

func NewAuthenticateService(dependencies AuthenticateDependencies) *AuthenticateService {
	hashPassword := dependencies.HashPassword
	if hashPassword == nil {
		hashPassword = security.HashPassword
	}
	dummyHash := dependencies.DummyHash
	if dummyHash == "" {
		dummyHash = _dummyBcryptHash
	}
	return &AuthenticateService{
		repository:   dependencies.Repository,
		tokens:       dependencies.Tokens,
		sessions:     dependencies.Sessions,
		logger:       slog.Default(),
		hashPassword: hashPassword,
		dummyHash:    dummyHash,
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
			return domain.User{}, SessionTokens{}, fmt.Errorf("lookup user account: %w", err)
		}
		dummyHash := service.dummyHash
		if dummyHash == "" {
			dummyHash = _dummyBcryptHash
		}
		_ = security.VerifyPassword(dummyHash, password)
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
	currentHash := account.PasswordHash
	if security.IsLegacyPasswordHash(account.PasswordHash) {
		upgradedHash, hashErr := service.hashPassword(password)
		if hashErr != nil {
			service.log().WarnContext(ctx, "upgrade legacy password hash failed", "error", hashErr)
		} else if upgraded, err := service.repository.UpgradePasswordHash(ctx, account.ID, account.PasswordHash, upgradedHash); err != nil {
			service.log().WarnContext(ctx, "persist upgraded password hash failed", "error", err)
		} else if upgraded {
			currentHash = upgradedHash
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
	if err := service.ensureCredentialsUnchanged(ctx, account.ID, currentHash); err != nil {
		return domain.User{}, SessionTokens{}, err
	}
	return account, tokens, nil
}

// ensureCredentialsUnchanged closes the window where a password reset finishes
// between the credential check and session issuance. Reset replaces the hash
// before it revokes sessions, so a session issued after that revocation always
// observes the new hash here and is withdrawn.
func (service *AuthenticateService) ensureCredentialsUnchanged(
	ctx context.Context,
	userID int,
	verifiedHash string,
) error {
	if service.sessions == nil {
		return nil
	}
	latest, err := service.repository.FindByID(ctx, userID)
	if err == nil && latest.PasswordHash == verifiedHash {
		return nil
	}
	if revokeErr := service.sessions.RevokeAll(context.WithoutCancel(ctx), userID, time.Now().UTC()); revokeErr != nil {
		service.log().WarnContext(ctx, "revoke session after credential change failed", "error", revokeErr)
	}
	if err != nil {
		return fmt.Errorf("recheck credentials after session issuance: %w", err)
	}
	return domain.ErrInvalidCredentials
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
