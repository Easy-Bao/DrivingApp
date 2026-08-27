package usecase

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"strconv"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

const refreshTokenBytes = 32

type roleTokenIssuer interface {
	IssueWithRole(subject, role string) (string, error)
}

type SessionTokens struct {
	AccessToken  string
	RefreshToken string
}

func issueToken(issuer domain.TokenIssuer, subject string, role domain.Role) (string, error) {
	if roleIssuer, ok := issuer.(roleTokenIssuer); ok {
		return roleIssuer.IssueWithRole(subject, string(role))
	}
	return issuer.Issue(subject)
}

func issueSessionTokens(ctx context.Context, sessions domain.RefreshSessionStore, issuer domain.TokenIssuer, subject string, role domain.Role) (SessionTokens, error) {
	accessToken, err := issueToken(issuer, subject, role)
	if err != nil {
		return SessionTokens{}, err
	}
	refreshToken, err := issueRefreshToken(ctx, sessions, subject, role)
	if err != nil {
		return SessionTokens{}, err
	}
	return SessionTokens{AccessToken: accessToken, RefreshToken: refreshToken}, nil
}

func issueRefreshToken(ctx context.Context, sessions domain.RefreshSessionStore, subject string, role domain.Role) (string, error) {
	if sessions == nil {
		return "", domain.ErrRefreshSessionUnavailable
	}
	userID, err := subjectID(subject)
	if err != nil {
		return "", err
	}

	refreshToken, tokenHash, err := newRefreshToken()
	if err != nil {
		return "", fmt.Errorf("generate refresh token: %w", err)
	}
	now := time.Now().UTC()
	if err := sessions.Create(ctx, domain.RefreshSession{
		UserID:    userID,
		TokenHash: tokenHash,
		ExpiresAt: now.Add(refreshTokenLifetime()),
	}); err != nil {
		return "", unavailableSessionError(err)
	}
	return refreshToken, nil
}

func replacementRefreshSession(userID int, now time.Time) (string, domain.RefreshSession, error) {
	refreshToken, tokenHash, err := newRefreshToken()
	if err != nil {
		return "", domain.RefreshSession{}, fmt.Errorf("generate replacement refresh token: %w", err)
	}
	return refreshToken, domain.RefreshSession{
		UserID:    userID,
		TokenHash: tokenHash,
		ExpiresAt: now.Add(refreshTokenLifetime()),
	}, nil
}

func newRefreshToken() (string, string, error) {
	bytes := make([]byte, refreshTokenBytes)
	if _, err := rand.Read(bytes); err != nil {
		return "", "", err
	}
	token := base64.RawURLEncoding.EncodeToString(bytes)
	return token, hashRefreshToken(token), nil
}

func hashRefreshToken(token string) string {
	digest := sha256.Sum256([]byte(token))
	return hex.EncodeToString(digest[:])
}

func subjectID(subject string) (int, error) {
	userID, err := strconv.Atoi(subject)
	if err != nil || userID <= 0 {
		return 0, fmt.Errorf("invalid account subject")
	}
	return userID, nil
}

func refreshTokenLifetime() time.Duration {
	return security.RefreshTokenLifetime
}

func unavailableSessionError(err error) error {
	if err == nil {
		return domain.ErrRefreshSessionUnavailable
	}
	return fmt.Errorf("%w: %w", domain.ErrRefreshSessionUnavailable, err)
}
