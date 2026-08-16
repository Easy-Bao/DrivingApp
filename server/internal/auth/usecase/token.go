package usecase

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
)

type roleTokenIssuer interface {
	IssueWithRole(subject, role string) (string, error)
}

type refreshRoleTokenIssuer interface {
	IssueRefreshWithRole(subject, role string) (string, error)
}

type refreshTokenVerifier interface {
	VerifyRefresh(rawToken string) (security.Identity, error)
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

func issueSessionTokens(issuer domain.TokenIssuer, subject string, role domain.Role) (SessionTokens, error) {
	accessToken, err := issueToken(issuer, subject, role)
	if err != nil {
		return SessionTokens{}, err
	}
	refreshToken, err := issueRefreshToken(issuer, subject, role)
	if err != nil {
		return SessionTokens{}, err
	}
	return SessionTokens{AccessToken: accessToken, RefreshToken: refreshToken}, nil
}

func issueRefreshToken(issuer domain.TokenIssuer, subject string, role domain.Role) (string, error) {
	if refreshIssuer, ok := issuer.(refreshRoleTokenIssuer); ok {
		return refreshIssuer.IssueRefreshWithRole(subject, string(role))
	}
	return "", nil
}

func verifyRefreshToken(issuer domain.TokenIssuer, rawToken string) (security.Identity, error) {
	verifier, ok := issuer.(refreshTokenVerifier)
	if !ok {
		return security.Identity{}, domain.ErrInvalidRefreshToken
	}
	identity, err := verifier.VerifyRefresh(rawToken)
	if err != nil || identity.Subject == "" {
		return security.Identity{}, domain.ErrInvalidRefreshToken
	}
	return identity, nil
}
