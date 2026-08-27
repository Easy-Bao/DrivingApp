package token

import "github.com/Easy-Bao/DrivingApp/server/internal/platform/security"

type Verifier = security.TokenManager

var (
	ErrInvalidToken = security.ErrInvalidToken
	ErrMissingToken = security.ErrMissingToken
)

func NewVerifier(secret string) *Verifier { return security.NewTokenManager(secret) }
