package middleware

import (
	"context"
	"net/http"
	"strconv"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

type contextKey string

const identityKey contextKey = "authenticated_identity"

const principalKey contextKey = "authenticated_principal"

type Principal struct {
	UserID int
	Role   string
}

func RequireAuth(tokenManager *security.TokenManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			identity, ok := IdentityFromRequest(request, tokenManager)
			if !ok {
				response.Error(writer, http.StatusUnauthorized, "Your session has expired. Please sign in again to continue.")
				return
			}
			userID, err := strconv.Atoi(identity.Subject)
			if err != nil || userID <= 0 {
				response.Error(writer, http.StatusUnauthorized, "Your session has expired. Please sign in again to continue.")
				return
			}
			contextValue := context.WithValue(request.Context(), identityKey, identity)
			contextValue = context.WithValue(contextValue, principalKey, Principal{UserID: userID, Role: identity.Role})
			next.ServeHTTP(writer, request.WithContext(contextValue))
		})
	}
}

func RequireRole(roles ...string) func(http.Handler) http.Handler {
	allowed := make(map[string]struct{}, len(roles))
	for _, role := range roles {
		if role = strings.TrimSpace(role); role != "" {
			allowed[role] = struct{}{}
		}
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			principal, ok := PrincipalFromRequest(request)
			if !ok {
				response.Error(writer, http.StatusUnauthorized, "Your session has expired. Please sign in again to continue.")
				return
			}
			if _, ok := allowed[principal.Role]; !ok {
				response.Error(writer, http.StatusForbidden, "You do not have permission to access this resource.")
				return
			}
			next.ServeHTTP(writer, request)
		})
	}
}

func RequireAdmin(authorizer *security.AdminAuthorizer) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			principal, ok := PrincipalFromRequest(request)
			if !ok {
				response.Error(writer, http.StatusUnauthorized, "Your session has expired. Please sign in again to continue.")
				return
			}
			if authorizer == nil || !authorizer.IsAdmin(strconv.Itoa(principal.UserID)) {
				response.Error(writer, http.StatusForbidden, "You do not have permission to access this resource.")
				return
			}
			next.ServeHTTP(writer, request)
		})
	}
}

func IdentityFromRequest(request *http.Request, tokenManager *security.TokenManager) (security.Identity, bool) {
	if request == nil {
		return security.Identity{}, false
	}
	if identity, ok := Identity(request); ok {
		return identity, true
	}
	if tokenManager == nil {
		return security.Identity{}, false
	}
	rawToken, ok := BearerToken(request.Header.Get("Authorization"))
	if !ok {
		return security.Identity{}, false
	}
	identity, err := tokenManager.VerifyIdentity(rawToken)
	return identity, err == nil && identity.Subject != ""
}

func AuthenticatedUserID(request *http.Request, tokenManager *security.TokenManager) (int, bool) {
	if request == nil {
		return 0, false
	}
	if principal, ok := PrincipalFromRequest(request); ok {
		return principal.UserID, true
	}
	identity, ok := IdentityFromRequest(request, tokenManager)
	if !ok {
		return 0, false
	}
	userID, err := strconv.Atoi(identity.Subject)
	if err != nil || userID <= 0 {
		return 0, false
	}
	return userID, true
}

func BearerToken(header string) (string, bool) {
	parts := strings.Fields(header)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return "", false
	}
	token := parts[1]
	return token, token != ""
}

func Identity(request *http.Request) (security.Identity, bool) {
	if request == nil {
		return security.Identity{}, false
	}
	identity, ok := request.Context().Value(identityKey).(security.Identity)
	return identity, ok && identity.Subject != ""
}

func Subject(request *http.Request) (string, bool) {
	identity, ok := Identity(request)
	return identity.Subject, ok
}

func PrincipalFromRequest(request *http.Request) (Principal, bool) {
	if request == nil {
		return Principal{}, false
	}
	principal, ok := request.Context().Value(principalKey).(Principal)
	return principal, ok && principal.UserID > 0
}
