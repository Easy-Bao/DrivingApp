package http

import (
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"net/http"
)

type Router struct {
	service  *usecase.Service
	verifier *token.Verifier
}

func NewRouter(service *usecase.Service, verifier *token.Verifier) *Router {
	return &Router{service: service, verifier: verifier}
}
func (router *Router) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/admin/stats", router.stats)
}
func (router *Router) stats(w http.ResponseWriter, r *http.Request) {
	raw := r.Header.Get("Authorization")
	if len(raw) < 7 {
		writeError(w, 401, "unauthorized")
		return
	}
	if _, err := router.verifier.Verify(raw[7:]); err != nil {
		writeError(w, 401, "unauthorized")
		return
	}
	stats, err := router.service.DashboardStats(r.Context())
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, stats)
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
