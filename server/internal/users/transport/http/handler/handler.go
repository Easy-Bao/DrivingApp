package handler

import (
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/shared-core/request"
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
func (handler *Handler) identity(r *http.Request) (int, bool) {
	if principal, ok := middleware.PrincipalFromRequest(r); ok {
		return principal.UserID, true
	}
	identity, ok := middleware.IdentityFromRequest(r, handler.verifier)
	value, parseErr := strconv.Atoi(identity.Subject)
	return value, ok && parseErr == nil
}
func (handler *Handler) Me(w http.ResponseWriter, r *http.Request) {
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
func (handler *Handler) Update(w http.ResponseWriter, r *http.Request) {
	id, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	var input dto.UpdateProfileRequest
	if sharedrequest.DecodeJSON(w, r, &input, 16<<10) != nil {
		writeError(w, 400, "invalid JSON")
		return
	}
	current, err := handler.service.Get(r.Context(), id)
	if err != nil {
		writeError(w, 404, "profile not found")
		return
	}
	profile, err := handler.service.Update(r.Context(), applyProfileUpdate(current, input))
	if err != nil {
		writeError(w, 400, "We could not update your profile. Check the details and try again.")
		return
	}
	writeJSON(w, 200, profile)
}

func applyProfileUpdate(current domain.Profile, input dto.UpdateProfileRequest) domain.Profile {
	if input.Name != nil {
		current.Name = *input.Name
	}
	if input.Phone != nil {
		current.Phone = *input.Phone
	}
	if input.Email != nil {
		current.Email = *input.Email
	}
	if input.Address != nil {
		current.Address = *input.Address
	}
	if input.PreferredRideType != nil {
		current.PreferredRideType = *input.PreferredRideType
	}
	if input.VehicleType != nil {
		current.VehicleType = *input.VehicleType
	}
	if input.PlateNumber != nil {
		current.PlateNumber = *input.PlateNumber
	}
	return current
}

func (handler *Handler) Profile(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
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

func (handler *Handler) ProfileUpdate(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	if err != nil || actorID != targetID {
		writeError(w, 403, "forbidden")
		return
	}
	handler.Update(w, r)
}

func (handler *Handler) Notifications(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || targetID != actorID {
		writeError(w, 403, "forbidden")
		return
	}
	page, err := sharedrequest.ParseOffsetPagination(r.URL.Query(), 50, 100)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid pagination")
		return
	}
	items, err := handler.service.Notifications(r.Context(), targetID, page.Limit, page.Offset)
	if err != nil {
		writeError(w, 500, "Notifications are temporarily unavailable.")
		return
	}
	writeJSON(w, 200, response.NewOffsetPage(items, page.Limit, page.Offset))
}

func (handler *Handler) Online(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, 403, "forbidden")
		return
	}
	profile, err := handler.service.Get(r.Context(), actorID)
	if err != nil {
		if ent.IsNotFound(err) {
			writeError(w, http.StatusForbidden, "driver profile required")
			return
		}
		writeError(w, http.StatusInternalServerError, "could not load driver profile")
		return
	}
	// Older clients persisted the driver-profile ID instead of the account ID.
	// The profile is still resolved from the verified account, so accepting that
	// legacy path value does not broaden access to another driver's profile.
	if targetID != actorID && targetID != profile.ID {
		writeError(w, 403, "forbidden")
		return
	}
	if profile.Role != "driver" {
		writeError(w, 403, "driver profile required")
		return
	}
	var input struct {
		IsOnline       *bool `json:"is_online"`
		LegacyIsOnline *bool `json:"isOnline"`
	}
	if sharedrequest.DecodeJSON(w, r, &input, 4<<10) != nil {
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
	response.Error(w, status, message)
}
