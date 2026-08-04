package token

import "github.com/Easy-Bao/DrivingApp/server/shared-core/security"

type Issuer = security.TokenManager

func NewIssuer(secret string) *Issuer { return security.NewTokenManager(secret) }
