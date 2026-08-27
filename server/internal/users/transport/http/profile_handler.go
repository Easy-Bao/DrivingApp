package http

import (
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service  *usecase.ProfileService
	verifier *security.TokenManager
}

func NewHandler(service *usecase.ProfileService, verifier *security.TokenManager) *Handler {
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
		response.Error(w, 401, "unauthorized")
		return
	}
	profile, err := handler.service.Get(r.Context(), id)
	if err != nil {
		writeProfileReadError(w, err)
		return
	}
	response.JSON(w, 200, profile)
}
func (handler *Handler) Update(w http.ResponseWriter, r *http.Request) {
	id, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	var input dto.UpdateProfileRequest
	if sharedrequest.DecodeJSON(w, r, &input, 16<<10) != nil {
		response.Error(w, 400, "invalid JSON")
		return
	}
	current, err := handler.service.Get(r.Context(), id)
	if err != nil {
		writeProfileReadError(w, err)
		return
	}
	if input.Gender != nil {
		normalizedGender, valid := domain.NormalizeGender(*input.Gender)
		if !valid {
			response.Error(w, http.StatusUnprocessableEntity, "Please choose a valid gender.")
			return
		}
		input.Gender = &normalizedGender
	}
	profile, err := handler.service.Update(r.Context(), applyProfileUpdate(current, input))
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Your profile is temporarily unavailable. Please try again.")
		return
	}
	response.JSON(w, 200, profile)
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
	if input.Gender != nil {
		current.Gender = *input.Gender
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
		response.Error(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || id != actorID {
		response.Error(w, 403, "forbidden")
		return
	}
	profile, err := handler.service.Get(r.Context(), id)
	if err != nil {
		writeProfileReadError(w, err)
		return
	}
	response.JSON(w, 200, profile)
}

func (handler *Handler) ProfileUpdate(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	if err != nil || actorID != targetID {
		response.Error(w, 403, "forbidden")
		return
	}
	handler.Update(w, r)
}

func (handler *Handler) Avatar(w http.ResponseWriter, r *http.Request) {
	actorID, targetID, ok := handler.profileTarget(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	if actorID != targetID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	avatar, err := handler.service.Avatar(r.Context(), targetID)
	if err != nil {
		writeAvatarError(w, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	w.Header().Set("Content-Type", avatar.ContentType)
	w.Header().Set("Content-Length", strconv.Itoa(len(avatar.Bytes)))
	w.WriteHeader(http.StatusOK)
	if _, err := w.Write(avatar.Bytes); err != nil {
		slog.DebugContext(r.Context(), "write avatar response failed", "error", err)
	}
}

func (handler *Handler) AvatarUpload(w http.ResponseWriter, r *http.Request) {
	actorID, targetID, ok := handler.profileTarget(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	if actorID != targetID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}

	maxBytes := handler.service.MaxAvatarBytes()
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes+(1<<20))
	if err := r.ParseMultipartForm(maxBytes); err != nil {
		response.Error(w, http.StatusBadRequest, "Please choose a JPEG or PNG photo under 2 MB.")
		return
	}
	if r.MultipartForm != nil {
		defer r.MultipartForm.RemoveAll()
	}
	file, _, err := r.FormFile("photo")
	if err != nil {
		response.Error(w, http.StatusBadRequest, "Please choose a profile photo to upload.")
		return
	}
	defer file.Close()
	content, err := io.ReadAll(io.LimitReader(file, maxBytes+1))
	if err != nil || int64(len(content)) > maxBytes {
		response.Error(w, http.StatusRequestEntityTooLarge, "The profile photo is too large.")
		return
	}
	profile, err := handler.service.SaveAvatar(r.Context(), targetID, content)
	if err != nil {
		writeAvatarError(w, err)
		return
	}
	response.JSON(w, http.StatusOK, profile)
}

func (handler *Handler) profileTarget(r *http.Request) (int, int, bool) {
	actorID, ok := handler.identity(r)
	if !ok {
		return 0, 0, false
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || targetID <= 0 {
		return actorID, 0, true
	}
	return actorID, targetID, true
}

func writeAvatarError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, domain.ErrInvalidAvatar):
		response.Error(w, http.StatusUnprocessableEntity, "Please choose a JPEG or PNG photo under 2 MB.")
	case errors.Is(err, domain.ErrAvatarNotFound):
		response.Error(w, http.StatusNotFound, "Profile photo not found.")
	case errors.Is(err, domain.ErrAvatarCorrupt):
		response.Error(w, http.StatusServiceUnavailable, "Your profile photo is temporarily unavailable.")
	default:
		response.Error(w, http.StatusInternalServerError, "Your profile photo is temporarily unavailable. Please try again.")
	}
}

func writeProfileReadError(w http.ResponseWriter, err error) {
	if ent.IsNotFound(err) {
		response.Error(w, http.StatusNotFound, "Profile not found.")
		return
	}
	response.Error(w, http.StatusInternalServerError, "Your profile is temporarily unavailable.")
}

func (handler *Handler) Notifications(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || targetID != actorID {
		response.Error(w, 403, "forbidden")
		return
	}
	page, err := sharedrequest.ParseOffsetPagination(r.URL.Query(), 50, 100)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid pagination")
		return
	}
	items, err := handler.service.Notifications(r.Context(), targetID, page.Limit, page.Offset)
	if err != nil {
		response.Error(w, 500, "Notifications are temporarily unavailable.")
		return
	}
	response.JSON(w, 200, response.NewOffsetPage(items, page.Limit, page.Offset))
}

func (handler *Handler) Online(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 403, "forbidden")
		return
	}
	profile, err := handler.service.Get(r.Context(), actorID)
	if err != nil {
		if ent.IsNotFound(err) {
			response.Error(w, http.StatusForbidden, "driver profile required")
			return
		}
		response.Error(w, http.StatusInternalServerError, "could not load driver profile")
		return
	}
	// Older clients persisted the driver-profile ID instead of the account ID.
	// The profile is still resolved from the verified account, so accepting that
	// legacy path value does not broaden access to another driver's profile.
	if targetID != actorID && targetID != profile.ID {
		response.Error(w, 403, "forbidden")
		return
	}
	if profile.Role != "driver" {
		response.Error(w, 403, "driver profile required")
		return
	}
	var input struct {
		IsOnline       *bool `json:"is_online"`
		LegacyIsOnline *bool `json:"isOnline"`
	}
	if sharedrequest.DecodeJSON(w, r, &input, 4<<10) != nil {
		response.Error(w, 400, "invalid online status")
		return
	}
	if input.IsOnline != nil {
		profile.IsOnline = *input.IsOnline
	} else if input.LegacyIsOnline != nil {
		profile.IsOnline = *input.LegacyIsOnline
	} else {
		response.Error(w, 400, "is_online is required")
		return
	}
	updated, err := handler.service.Update(r.Context(), profile)
	if err != nil {
		response.Error(w, 500, "could not update online status")
		return
	}
	response.JSON(w, 200, updated)
}
