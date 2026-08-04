package handler

import (
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"net/http"
	"strconv"
)

type Handler struct {
	service  *usecase.Service
	verifier *token.Verifier
}

func NewHandler(service *usecase.Service, verifier *token.Verifier) *Handler {
	return &Handler{service: service, verifier: verifier}
}
func (handler *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/users/me", handler.me)
	mux.HandleFunc("PATCH /api/v1/users/me", handler.update)
	mux.HandleFunc("GET /api/v1/passengers/{id}", handler.profile)
	mux.HandleFunc("PUT /api/v1/passengers/{id}", handler.profileUpdate)
	mux.HandleFunc("GET /api/v1/drivers/{id}", handler.profile)
	mux.HandleFunc("POST /api/v1/drivers/{id}/online", handler.online)
	mux.HandleFunc("GET /api/v1/passengers/{id}/notifications", handler.notifications)
	mux.HandleFunc("GET /passengers/{id}", handler.profile)
	mux.HandleFunc("PUT /passengers/{id}", handler.profileUpdate)
	mux.HandleFunc("GET /drivers/{id}", handler.profile)
	mux.HandleFunc("POST /drivers/{id}/online", handler.online)
	mux.HandleFunc("GET /passengers/{id}/notifications", handler.notifications)
}
func (handler *Handler) identity(r *http.Request) (int, bool) {
	raw := r.Header.Get("Authorization")
	if len(raw) < 7 {
		return 0, false
	}
	id, err := handler.verifier.Verify(raw[7:])
	value, parseErr := strconv.Atoi(id)
	return value, err == nil && parseErr == nil
}
func (handler *Handler) me(w http.ResponseWriter, r *http.Request) {
	id, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	profile, err := handler.service.Get(r.Context(), id)
	if err != nil {
		writeError(w, 404, "profile not found")
		return
	}
	writeJSON(w, 200, profile)
}
func (handler *Handler) update(w http.ResponseWriter, r *http.Request) {
	id, ok := handler.identity(r)
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
	if input.ID == 0 {
		current, err := handler.service.Get(r.Context(), id)
		if err != nil {
			writeError(w, 404, "profile not found")
			return
		}
		input.ID = current.ID
		if input.Role == "" {
			input.Role = current.Role
		}
	}
	profile, err := handler.service.Update(r.Context(), input)
	if err != nil {
		writeError(w, 400, err.Error())
		return
	}
	writeJSON(w, 200, profile)
}

func (handler *Handler) profile(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil || id != actorID {
		writeError(w, 403, "forbidden")
		return
	}
	profile, err := handler.service.Get(r.Context(), id)
	if err != nil {
		writeError(w, 404, "profile not found")
		return
	}
	writeJSON(w, 200, profile)
}

func (handler *Handler) profileUpdate(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	targetID, err := strconv.Atoi(r.PathValue("id"))
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	if err != nil || actorID != targetID {
		writeError(w, 403, "forbidden")
		return
	}
	handler.update(w, r)
}

func (handler *Handler) notifications(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil || targetID != actorID {
		writeError(w, 403, "forbidden")
		return
	}
	items, err := handler.service.Notifications(r.Context(), targetID)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, items)
}

func (handler *Handler) online(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil || targetID != actorID {
		writeError(w, 403, "forbidden")
		return
	}
	profile, err := handler.service.Get(r.Context(), actorID)
	if err != nil || profile.Role != "driver" {
		writeError(w, 403, "driver profile required")
		return
	}
	var input struct {
		IsOnline       *bool `json:"is_online"`
		LegacyIsOnline *bool `json:"isOnline"`
	}
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 4<<10)).Decode(&input) != nil {
		writeError(w, 400, "invalid online status")
		return
	}
	if input.IsOnline != nil {
		profile.IsOnline = *input.IsOnline
	} else if input.LegacyIsOnline != nil {
		profile.IsOnline = *input.LegacyIsOnline
	} else {
		writeError(w, 400, "is_online is required")
		return
	}
	updated, err := handler.service.Update(r.Context(), profile)
	if err != nil {
		writeError(w, 500, "could not update online status")
		return
	}
	writeJSON(w, 200, updated)
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	response.JSON(w, status, value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
