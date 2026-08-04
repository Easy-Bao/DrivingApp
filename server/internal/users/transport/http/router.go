package http

import (
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"net/http"
	"strconv"
)

type Router struct {
	service  *usecase.Service
	verifier *token.Verifier
}

func NewRouter(service *usecase.Service, verifier *token.Verifier) *Router {
	return &Router{service: service, verifier: verifier}
}
func (router *Router) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/users/me", router.me)
	mux.HandleFunc("PATCH /api/v1/users/me", router.update)
}
func (router *Router) identity(r *http.Request) (int, bool) {
	raw := r.Header.Get("Authorization")
	if len(raw) < 7 {
		return 0, false
	}
	id, err := router.verifier.Verify(raw[7:])
	value, parseErr := strconv.Atoi(id)
	return value, err == nil && parseErr == nil
}
func (router *Router) me(w http.ResponseWriter, r *http.Request) {
	id, ok := router.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	profile, err := router.service.Get(r.Context(), id)
	if err != nil {
		writeError(w, 404, "profile not found")
		return
	}
	writeJSON(w, 200, profile)
}
func (router *Router) update(w http.ResponseWriter, r *http.Request) {
	id, ok := router.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	var input domain.Profile
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(&input) != nil {
		writeError(w, 400, "invalid JSON")
		return
	}
	input.UserID = id
	profile, err := router.service.Update(r.Context(), input)
	if err != nil {
		writeError(w, 400, err.Error())
		return
	}
	writeJSON(w, 200, profile)
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
