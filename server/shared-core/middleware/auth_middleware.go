package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
)

type contextKey string

const identityKey contextKey = "authenticated_identity"

func RequireAuth(tokenManager *security.TokenManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			identity, ok := IdentityFromRequest(request, tokenManager)
			if !ok {
				response.Error(writer, http.StatusUnauthorized, "unauthorized")
				return
			}
			next.ServeHTTP(writer, request.WithContext(context.WithValue(request.Context(), identityKey, identity)))
		})
	}
}

func IdentityFromRequest(request *http.Request, tokenManager *security.TokenManager) (security.Identity, bool) {
	if request == nil || tokenManager == nil {
		return security.Identity{}, false
	}
	rawToken, ok := BearerToken(request.Header.Get("Authorization"))
	if !ok {
		return security.Identity{}, false
	}
	identity, err := tokenManager.VerifyIdentity(rawToken)
	return identity, err == nil && identity.Subject != ""
}

func BearerToken(header string) (string, bool) {
	const prefix = "Bearer "
	header = strings.TrimSpace(header)
	if len(header) <= len(prefix) || !strings.HasPrefix(header, prefix) {
		return "", false
	}
	token := strings.TrimSpace(strings.TrimPrefix(header, prefix))
	return token, token != ""
}

func Identity(request *http.Request) (security.Identity, bool) {
	identity, ok := request.Context().Value(identityKey).(security.Identity)
	return identity, ok && identity.Subject != ""
}

func Subject(request *http.Request) (string, bool) {
	identity, ok := Identity(request)
	return identity.Subject, ok
}
