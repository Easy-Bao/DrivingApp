package handler

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service  *usecase.Service
	verifier *token.Verifier
}

func NewHandler(service *usecase.Service, verifier *token.Verifier) *Handler {
	return &Handler{service: service, verifier: verifier}
}
func (handler *Handler) RegisterRoutes(router chi.Router) {
	router.Get("/api/v1/admin/stats", handler.stats)
}
func (handler *Handler) stats(w http.ResponseWriter, r *http.Request) {
	raw := r.Header.Get("Authorization")
	if len(raw) < 7 {
		writeError(w, 401, "unauthorized")
		return
	}
	if _, err := handler.verifier.Verify(raw[7:]); err != nil {
		writeError(w, 401, "unauthorized")
		return
	}
	stats, err := handler.service.DashboardStats(r.Context())
	if err != nil {
		writeError(w, 500, err.Error())
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
