package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
)

type contextKey string

const subjectKey contextKey = "authenticated_subject"

func RequireAuth(tokenManager *security.TokenManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			rawToken := strings.TrimPrefix(request.Header.Get("Authorization"), "Bearer ")
			subject, err := tokenManager.Verify(rawToken)
			if err != nil {
				response.Error(writer, http.StatusUnauthorized, "unauthorized")
				return
			}
			next.ServeHTTP(writer, request.WithContext(context.WithValue(request.Context(), subjectKey, subject)))
		})
	}
}

func Subject(request *http.Request) (string, bool) {
	subject, ok := request.Context().Value(subjectKey).(string)
	return subject, ok && subject != ""
}
