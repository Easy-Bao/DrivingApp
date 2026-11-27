package http

import (
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service  *app.ProfileService
	verifier *security.TokenManager
}

type Dependencies struct {
	Service       *app.ProfileService
	Verifier      *security.TokenManager
	RouteSecurity *middleware.RouteSecurity
}

func NewHandler(dependencies Dependencies) *Handler {
	return &Handler{service: dependencies.Service, verifier: dependencies.Verifier}
}
func (handler *Handler) identity(r *http.Request) (int, bool) {
	return middleware.AuthenticatedUserID(r, handler.verifier)
}
func (handler *Handler) Me(w http.ResponseWriter, r *http.Request) {
	id, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	if !handler.ensureProfileService(w) {
		return
	}
	profile, err := handler.service.Get(r.Context(), id)
	if err != nil {
		writeProfileReadError(w, err)
		return
	}
	response.JSON(w, http.StatusOK, NewProfileResponse(profile))
}
func (handler *Handler) Update(w http.ResponseWriter, r *http.Request) {
	id, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input UpdateProfileRequest
	if sharedrequest.DecodeJSON(w, r, &input, 16<<10) != nil {
		response.Error(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	if !handler.ensureProfileService(w) {
		return
	}
	if input.Name != nil {
		trimmedName := strings.TrimSpace(*input.Name)
		if trimmedName == "" || len([]rune(trimmedName)) > 100 {
			response.Error(w, http.StatusUnprocessableEntity, "Please enter a valid name.")
			return
		}
		input.Name = &trimmedName
	}
	if input.Address != nil {
		trimmedAddress := strings.TrimSpace(*input.Address)
		if len([]rune(trimmedAddress)) > 255 {
			response.Error(w, http.StatusUnprocessableEntity, "Address must be 255 characters or fewer.")
			return
		}
		input.Address = &trimmedAddress
	}
	if input.Gender != nil {
		normalizedGender, valid := domain.NormalizeGender(*input.Gender)
		if !valid {
			response.Error(w, http.StatusUnprocessableEntity, "Please choose a valid gender.")
			return
		}
		input.Gender = &normalizedGender
	}
	if input.VehicleType != nil {
		trimmedVehicleType := strings.TrimSpace(*input.VehicleType)
		if trimmedVehicleType == "" || len([]rune(trimmedVehicleType)) > 80 {
			response.Error(w, http.StatusUnprocessableEntity, "Please enter a valid vehicle type.")
			return
		}
		input.VehicleType = &trimmedVehicleType
	}
	if input.PlateNumber != nil {
		trimmedPlateNumber := strings.TrimSpace(*input.PlateNumber)
		if trimmedPlateNumber == "" || len([]rune(trimmedPlateNumber)) > 32 {
			response.Error(w, http.StatusUnprocessableEntity, "Please enter a valid plate number.")
			return
		}
		input.PlateNumber = &trimmedPlateNumber
	}
	patch := domain.ProfilePatch{
		Name:        input.Name,
		Email:       input.Email,
		Phone:       input.Phone,
		Address:     input.Address,
		Gender:      input.Gender,
		VehicleType: input.VehicleType,
		PlateNumber: input.PlateNumber,
	}
	profile, err := handler.service.Patch(r.Context(), id, patch)
	if err != nil {
		switch {
		case errors.Is(err, domain.ErrProfileNotFound):
			writeProfileReadError(w, err)
		case errors.Is(err, domain.ErrEmailChangeNotAllowed):
			response.Error(w, http.StatusUnprocessableEntity, "Use the email verification flow to change your email.")
		case errors.Is(err, domain.ErrPhoneChangeNotAllowed):
			response.Error(w, http.StatusUnprocessableEntity, "Phone changes require verification and cannot be made here.")
		case errors.Is(err, domain.ErrDriverVehicleChangeWhileOnline):
			response.Error(w, http.StatusConflict, "Go offline before changing vehicle information.")
		case errors.Is(err, domain.ErrInvalidRole):
			response.Error(w, http.StatusBadRequest, "unsupported profile role")
		default:
			response.Error(w, http.StatusInternalServerError, "Your profile is temporarily unavailable. Please try again.")
		}
		return
	}
	response.JSON(w, http.StatusOK, NewProfileResponse(profile))
}

func (handler *Handler) Profile(w http.ResponseWriter, r *http.Request) {
	handler.profileByID(w, r, "invalid passenger id")
}

func (handler *Handler) DriverProfile(w http.ResponseWriter, r *http.Request) {
	handler.profileByID(w, r, "invalid driver id")
}

func (handler *Handler) profileByID(w http.ResponseWriter, r *http.Request, invalidMessage string) {
	id, ok := handler.authorizedAccountID(w, r, invalidMessage)
	if !ok {
		return
	}
	if !handler.ensureProfileService(w) {
		return
	}
	profile, err := handler.service.Get(r.Context(), id)
	if err != nil {
		writeProfileReadError(w, err)
		return
	}
	response.JSON(w, http.StatusOK, NewProfileResponse(profile))
}

func (handler *Handler) ProfileUpdate(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.authorizedPassengerID(w, r); !ok {
		return
	}
	handler.Update(w, r)
}

func (handler *Handler) Avatar(w http.ResponseWriter, r *http.Request) {
	targetID, ok := handler.authorizedPassengerID(w, r)
	if !ok {
		return
	}
	if handler == nil || handler.service == nil {
		response.Error(w, http.StatusInternalServerError, "Your profile photo is temporarily unavailable. Please try again.")
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
	targetID, ok := handler.authorizedPassengerID(w, r)
	if !ok {
		return
	}
	if handler == nil || handler.service == nil {
		response.Error(w, http.StatusInternalServerError, "Your profile photo is temporarily unavailable. Please try again.")
		return
	}

	maxBytes := handler.service.MaxAvatarBytes()
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes+(1<<20))
	if err := r.ParseMultipartForm(maxBytes); err != nil {
		if _, tooLarge := errors.AsType[*http.MaxBytesError](err); tooLarge {
			response.Error(w, http.StatusRequestEntityTooLarge, "The profile photo is too large.")
			return
		}
		response.Error(w, http.StatusBadRequest, "Please choose a JPEG or PNG photo under 2 MB.")
		return
	}
	if r.MultipartForm != nil {
		defer func() {
			if err := r.MultipartForm.RemoveAll(); err != nil {
				slog.DebugContext(r.Context(), "remove profile upload temporary files failed", "error", err)
			}
		}()
	}
	file, _, err := r.FormFile("photo")
	if err != nil {
		response.Error(w, http.StatusBadRequest, "Please choose a profile photo to upload.")
		return
	}
	defer func() {
		if err := file.Close(); err != nil {
			slog.DebugContext(r.Context(), "close profile upload failed", "error", err)
		}
	}()
	content, err := io.ReadAll(io.LimitReader(file, maxBytes+1))
	if err != nil {
		if _, tooLarge := errors.AsType[*http.MaxBytesError](err); tooLarge {
			response.Error(w, http.StatusRequestEntityTooLarge, "The profile photo is too large.")
			return
		}
		response.Error(w, http.StatusBadRequest, "The profile photo could not be read.")
		return
	}
	if int64(len(content)) > maxBytes {
		response.Error(w, http.StatusRequestEntityTooLarge, "The profile photo is too large.")
		return
	}
	profile, err := handler.service.SaveAvatar(r.Context(), targetID, content)
	if err != nil {
		writeAvatarError(w, err)
		return
	}
	response.JSON(w, http.StatusOK, NewProfileResponse(profile))
}

func (handler *Handler) authorizedPassengerID(w http.ResponseWriter, r *http.Request) (int, bool) {
	return handler.authorizedAccountID(w, r, "invalid passenger id")
}

func (handler *Handler) authorizedAccountID(w http.ResponseWriter, r *http.Request, invalidMessage string) (int, bool) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return 0, false
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || targetID <= 0 {
		response.Error(w, http.StatusBadRequest, invalidMessage)
		return 0, false
	}
	if actorID != targetID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return 0, false
	}
	return targetID, true
}

func (handler *Handler) ensureProfileService(w http.ResponseWriter) bool {
	if handler != nil && handler.service != nil {
		return true
	}
	response.Error(w, http.StatusInternalServerError, "Your profile is temporarily unavailable.")
	return false
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
	if errors.Is(err, domain.ErrProfileNotFound) {
		response.Error(w, http.StatusNotFound, "Profile not found.")
		return
	}
	response.Error(w, http.StatusInternalServerError, "Your profile is temporarily unavailable.")
}

func (handler *Handler) Notifications(w http.ResponseWriter, r *http.Request) {
	targetID, ok := handler.authorizedPassengerID(w, r)
	if !ok {
		return
	}
	page, err := sharedrequest.ParseOffsetPagination(r.URL.Query(), 50, 100)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid pagination")
		return
	}
	if handler == nil || handler.service == nil {
		response.Error(w, http.StatusInternalServerError, "Notifications are temporarily unavailable.")
		return
	}
	items, err := handler.service.Notifications(r.Context(), targetID, page.Limit, page.Offset)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Notifications are temporarily unavailable.")
		return
	}
	response.JSON(w, http.StatusOK, response.NewOffsetPage(NewNotificationResponses(items), page.Limit, page.Offset))
}

func (handler *Handler) MarkAllNotificationsRead(w http.ResponseWriter, r *http.Request) {
	targetID, ok := handler.authorizedPassengerID(w, r)
	if !ok {
		return
	}
	if handler == nil || handler.service == nil {
		response.Error(w, http.StatusInternalServerError, "Notifications could not be marked as read.")
		return
	}
	if err := handler.service.MarkAllNotificationsRead(r.Context(), targetID); err != nil {
		response.Error(w, http.StatusInternalServerError, "Notifications could not be marked as read.")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (handler *Handler) DeleteNotification(w http.ResponseWriter, r *http.Request) {
	targetID, ok := handler.authorizedPassengerID(w, r)
	if !ok {
		return
	}
	notificationID, err := strconv.Atoi(chi.URLParam(r, "notificationID"))
	if err != nil || notificationID <= 0 {
		response.Error(w, http.StatusBadRequest, "invalid notification")
		return
	}
	if handler == nil || handler.service == nil {
		response.Error(w, http.StatusInternalServerError, "The notification could not be deleted.")
		return
	}
	if err := handler.service.DeleteNotification(r.Context(), targetID, notificationID); err != nil {
		if errors.Is(err, domain.ErrNotificationNotFound) {
			response.Error(w, http.StatusNotFound, "notification not found")
			return
		}
		response.Error(w, http.StatusInternalServerError, "The notification could not be deleted.")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (handler *Handler) Online(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || targetID <= 0 {
		response.Error(w, http.StatusBadRequest, "invalid driver id")
		return
	}
	var input struct {
		IsOnline       *bool `json:"is_online"`
		LegacyIsOnline *bool `json:"isOnline"`
	}
	if sharedrequest.DecodeJSON(w, r, &input, 4<<10) != nil {
		response.Error(w, http.StatusBadRequest, "invalid online status")
		return
	}
	var isOnline bool
	if input.IsOnline != nil {
		isOnline = *input.IsOnline
	} else if input.LegacyIsOnline != nil {
		isOnline = *input.LegacyIsOnline
	} else {
		response.Error(w, http.StatusBadRequest, "is_online is required")
		return
	}
	if handler == nil || handler.service == nil {
		response.Error(w, http.StatusInternalServerError, "could not update online status")
		return
	}
	// The verified account ID and the legacy profile-ID path are both accepted
	// by one scoped update query, avoiding a full profile read/write cycle.
	updated, err := handler.service.UpdateOnlineStatus(
		r.Context(),
		actorID,
		targetID,
		isOnline,
	)
	if err != nil {
		if errors.Is(err, domain.ErrDriverAvailabilityBlocked) {
			response.Error(w, http.StatusConflict, "Finish your active ride before going offline.")
			return
		}
		if errors.Is(err, domain.ErrProfileNotFound) {
			response.Error(w, http.StatusForbidden, "forbidden")
			return
		}
		response.Error(w, http.StatusInternalServerError, "could not update online status")
		return
	}
	response.JSON(w, http.StatusOK, NewProfileResponse(updated))
}
