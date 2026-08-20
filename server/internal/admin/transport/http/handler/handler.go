package handler

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
)

type Handler struct {
	service    *usecase.Service
	verifier   *token.Verifier
	authorizer *security.AdminAuthorizer
}

func NewHandler(service *usecase.Service, verifier *token.Verifier, authorizer *security.AdminAuthorizer) *Handler {
	return &Handler{service: service, verifier: verifier, authorizer: authorizer}
}
func (handler *Handler) Stats(w http.ResponseWriter, r *http.Request) {
	const prefix = "Bearer "
	raw := r.Header.Get("Authorization")
	if handler.verifier == nil || len(raw) <= len(prefix) || raw[:len(prefix)] != prefix {
		writeError(w, 401, "unauthorized")
		return
	}
	identity, err := handler.verifier.VerifyIdentity(raw[len(prefix):])
	if err != nil {
		writeError(w, 401, "unauthorized")
		return
	}
	if !handler.authorizer.IsAdmin(identity.Subject) {
		writeError(w, 403, "forbidden")
		return
	}
	stats, err := handler.service.DashboardStats(r.Context())
	if err != nil {
		writeError(w, 500, "Dashboard statistics are temporarily unavailable.")
		return
	}
	writeJSON(w, 200, stats)
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	response.JSON(w, status, value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
