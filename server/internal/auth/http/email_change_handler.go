package http

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

type requestEmailChange struct {
	CurrentPassword string `json:"current_password"`
	Email           string `json:"email"`
}

type confirmEmailChange struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

func (handler *Handler) RequestEmailChange(writer http.ResponseWriter, request *http.Request) {
	userID, ok := middleware.AuthenticatedUserID(request, handler.verifier)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input requestEmailChange
	if !decode(writer, request, &input) {
		return
	}
	if err := handler.otp.RequestEmailChange(
		request.Context(),
		userID,
		input.CurrentPassword,
		input.Email,
	); err != nil {
		writeEmailChangeError(writer, request, err)
		return
	}
	response.JSON(writer, http.StatusAccepted, map[string]string{
		"message": "verification code sent to the new email address",
	})
}

func (handler *Handler) ConfirmEmailChange(writer http.ResponseWriter, request *http.Request) {
	userID, ok := middleware.AuthenticatedUserID(request, handler.verifier)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input confirmEmailChange
	if !decode(writer, request, &input) {
		return
	}
	if err := handler.otp.ConfirmEmailChange(request.Context(), userID, input.Email, input.Code); err != nil {
		writeEmailChangeError(writer, request, err)
		return
	}
	writer.WriteHeader(http.StatusNoContent)
}

func writeEmailChangeError(writer http.ResponseWriter, request *http.Request, err error) {
	switch {
	case errors.Is(err, domain.ErrInvalidCredentials):
		response.Error(writer, http.StatusUnauthorized, "current credentials are invalid")
	case errors.Is(err, domain.ErrEmailTaken):
		response.Error(writer, http.StatusConflict, "email address is already registered")
	case errors.Is(err, domain.ErrEmailChangeStale):
		response.Error(writer, http.StatusConflict, "email change request is no longer valid")
	case errors.Is(err, domain.ErrOTPMaxAttemptsExceeded):
		writer.Header().Set("Retry-After", "900")
		response.Error(writer, http.StatusTooManyRequests, "too many verification attempts")
	case errors.Is(err, domain.ErrOTPUnavailable):
		response.Error(writer, http.StatusServiceUnavailable, "email verification is temporarily unavailable")
	case errors.Is(err, domain.ErrInvalidEmail),
		errors.Is(err, domain.ErrEmailUnchanged),
		errors.Is(err, domain.ErrInvalidOTP),
		errors.Is(err, domain.ErrOTPRequired):
		response.Error(writer, http.StatusBadRequest, "email change request is invalid or expired")
	default:
		slog.WarnContext(request.Context(), "email change request failed", "error", err)
		response.Error(writer, http.StatusInternalServerError, "email change is temporarily unavailable")
	}
}
