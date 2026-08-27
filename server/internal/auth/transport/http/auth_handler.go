package http

import (
	"errors"
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

type Handler struct {
	register     *usecase.RegisterService
	authenticate *usecase.AuthenticateService
	otp          *usecase.OTPService
}

func NewHandler(register *usecase.RegisterService, authenticate *usecase.AuthenticateService, otp *usecase.OTPService) *Handler {
	return &Handler{register: register, authenticate: authenticate, otp: otp}
}
func (handler *Handler) PassengerRegister(w http.ResponseWriter, r *http.Request) {
	handler.registerAccount(w, r, false)
}
func (handler *Handler) DriverRegister(w http.ResponseWriter, r *http.Request) {
	handler.registerAccount(w, r, true)
}
func (handler *Handler) registerAccount(w http.ResponseWriter, r *http.Request, driver bool) {
	var input dto.RegistrationRequest
	if !decode(w, r, &input) {
		return
	}
	handler.registerDecoded(w, r, input, driver)
}

func (handler *Handler) GenericRegister(w http.ResponseWriter, r *http.Request) {
	var input dto.GenericRegistrationRequest
	if !decode(w, r, &input) {
		return
	}
	if input.Role != string(domain.Driver) && input.Role != string(domain.Passenger) {
		response.Error(w, http.StatusBadRequest, "role must be passenger or driver")
		return
	}
	handler.registerDecoded(w, r, input.RegistrationRequest, input.Role == string(domain.Driver))
}

func (handler *Handler) registerDecoded(w http.ResponseWriter, r *http.Request, input dto.RegistrationRequest, driver bool) {
	if !driver {
		if handler.otp == nil {
			response.Error(w, http.StatusServiceUnavailable, "passenger verification is unavailable")
			return
		}
		pending, err := handler.otp.RegisterPassenger(r.Context(), toRegisterInput(input))
		if err != nil {
			status := http.StatusBadRequest
			if errors.Is(err, domain.ErrEmailTaken) || errors.Is(err, domain.ErrAccountConflict) {
				status = http.StatusConflict
			}
			if errors.Is(err, domain.ErrOTPUnavailable) {
				status = http.StatusServiceUnavailable
			}
			response.Error(w, status, safeAuthError(err))
			return
		}
		response.JSON(w, http.StatusAccepted, map[string]any{
			"success": true,
			"data": map[string]any{
				"email":             pending.Email,
				"needsVerification": true,
			},
		})
		return
	}
	var account domain.User
	var token string
	var err error
	if driver {
		account, token, err = handler.register.Driver(r.Context(), toRegisterInput(input))
	}
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, domain.ErrEmailTaken) || errors.Is(err, domain.ErrAccountConflict) {
			status = http.StatusConflict
		}
		response.Error(w, status, safeAuthError(err))
		return
	}
	refreshToken, err := handler.register.IssueRefreshToken(r.Context(), account)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, safeAuthError(err))
		return
	}
	response.JSON(w, http.StatusCreated, authSessionResponse(account, token, refreshToken, !account.IsVerified))
}
func (handler *Handler) Login(w http.ResponseWriter, r *http.Request) {
	handler.login(w, r, "")
}

func (handler *Handler) PassengerLogin(w http.ResponseWriter, r *http.Request) {
	handler.login(w, r, domain.Passenger)
}

func (handler *Handler) DriverLogin(w http.ResponseWriter, r *http.Request) {
	handler.login(w, r, domain.Driver)
}

func (handler *Handler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	var input dto.RefreshToken
	if !decode(w, r, &input) {
		return
	}
	tokens, err := handler.authenticate.Refresh(r.Context(), input.Token)
	if err != nil {
		status := http.StatusServiceUnavailable
		if errors.Is(err, domain.ErrInvalidRefreshToken) {
			status = http.StatusUnauthorized
		}
		response.Error(w, status, safeAuthError(err))
		return
	}
	response.JSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data": map[string]any{
			"token":        tokens.AccessToken,
			"refreshToken": tokens.RefreshToken,
		},
	})
}

func (handler *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	var input dto.RefreshToken
	if !decode(w, r, &input) {
		return
	}
	if err := handler.authenticate.Logout(r.Context(), input.Token); err != nil {
		status := http.StatusServiceUnavailable
		if errors.Is(err, domain.ErrInvalidRefreshToken) {
			status = http.StatusUnauthorized
		}
		response.Error(w, status, safeAuthError(err))
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (handler *Handler) login(w http.ResponseWriter, r *http.Request, role domain.Role) {
	var input dto.LoginRequest
	if !decode(w, r, &input) {
		return
	}
	account, tokens, err := handler.authenticate.ExecuteSessionAs(r.Context(), input.Email, input.Password, role)
	if err != nil {
		response.Error(w, http.StatusUnauthorized, "email or password is incorrect")
		return
	}
	response.JSON(w, http.StatusOK, authSessionResponse(account, tokens.AccessToken, tokens.RefreshToken, !account.IsVerified))
}

func (handler *Handler) RequestOTP(w http.ResponseWriter, r *http.Request) {
	if handler.otp == nil {
		response.Error(w, http.StatusServiceUnavailable, "otp delivery is unavailable")
		return
	}
	var input dto.OTPRequest
	if !decode(w, r, &input) {
		return
	}
	if err := handler.otp.RequestVerification(r.Context(), input.Email); err != nil {
		response.Error(w, http.StatusBadRequest, safeAuthError(err))
		return
	}
	response.JSON(w, http.StatusAccepted, map[string]any{"success": true, "data": map[string]bool{"sent": true}})
}

func (handler *Handler) VerifyOTP(w http.ResponseWriter, r *http.Request) {
	if handler.otp == nil {
		response.Error(w, http.StatusServiceUnavailable, "otp delivery is unavailable")
		return
	}
	var input dto.OTPVerification
	if !decode(w, r, &input) {
		return
	}

	account, token, err := handler.otp.VerifyPassenger(r.Context(), input.Email, input.Code)

	if err != nil {
		response.Error(w, http.StatusBadRequest, safeAuthError(err))
		return
	}
	refreshToken, err := handler.otp.IssueRefreshToken(r.Context(), account)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, safeAuthError(err))
		return
	}
	sessionResponse := authSessionResponse(account, token, refreshToken, false)
	sessionResponse["data"].(map[string]any)["verified"] = true
	response.JSON(w, http.StatusOK, sessionResponse)
}

func (handler *Handler) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	handler.forgotPasswordForRole(w, r, domain.Passenger)
}

func (handler *Handler) DriverForgotPassword(w http.ResponseWriter, r *http.Request) {
	handler.forgotPasswordForRole(w, r, domain.Driver)
}

func (handler *Handler) forgotPasswordForRole(w http.ResponseWriter, r *http.Request, role domain.Role) {
	if handler.otp == nil {
		response.Error(w, http.StatusServiceUnavailable, "otp delivery is unavailable")
		return
	}
	var input dto.OTPRequest
	if !decode(w, r, &input) {
		return
	}
	if err := handler.otp.RequestPasswordResetForRole(r.Context(), input.Email, role); err != nil {
		response.Error(w, http.StatusBadRequest, safeAuthError(err))
		return
	}
	response.JSON(w, http.StatusOK, map[string]any{"success": true, "data": map[string]bool{"success": true}})
}

func (handler *Handler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	handler.resetPasswordForRole(w, r, domain.Passenger)
}

func (handler *Handler) DriverResetPassword(w http.ResponseWriter, r *http.Request) {
	handler.resetPasswordForRole(w, r, domain.Driver)
}

func (handler *Handler) resetPasswordForRole(w http.ResponseWriter, r *http.Request, role domain.Role) {
	if handler.otp == nil {
		response.Error(w, http.StatusServiceUnavailable, "otp delivery is unavailable")
		return
	}
	var input dto.PasswordReset
	if !decode(w, r, &input) {
		return
	}
	if err := handler.otp.ResetPasswordForRole(r.Context(), input.Email, input.Code, input.NewPassword, role); err != nil {
		response.Error(w, http.StatusBadRequest, safeAuthError(err))
		return
	}
	response.JSON(w, http.StatusOK, map[string]any{"success": true, "message": "password reset successful"})
}

func toRegisterInput(input dto.RegistrationRequest) usecase.RegisterInput {
	return usecase.RegisterInput{Email: input.Email, Phone: input.Phone, Name: input.Name, Password: input.Password, VehicleType: input.VehicleType, PlateNumber: input.PlateNumber}
}

func decode(w http.ResponseWriter, r *http.Request, value any) bool {
	if sharedrequest.DecodeJSON(w, r, value, 16<<10) != nil {
		response.Error(w, http.StatusBadRequest, "invalid JSON")
		return false
	}
	return true
}
func safeAuthError(err error) string {
	switch {
	case errors.Is(err, domain.ErrEmailTaken):
		return "That email is already registered."
	case errors.Is(err, domain.ErrAccountConflict):
		return "That email or phone number is already registered."
	case errors.Is(err, domain.ErrInvalidCredentials):
		return "The email or password is incorrect."
	case errors.Is(err, domain.ErrInvalidRole):
		return "Choose a valid account type."
	case errors.Is(err, domain.ErrOTPRequired):
		return "Enter the verification code to continue."
	case errors.Is(err, domain.ErrInvalidOTP):
		return "That verification code is invalid or expired."
	case errors.Is(err, domain.ErrOTPUnavailable):
		return "Verification is temporarily unavailable. Please try again."
	case errors.Is(err, domain.ErrPendingRegistrationNotFound):
		return "Your registration could not be found. Please start again."
	case errors.Is(err, domain.ErrInvalidRefreshToken):
		return "Your session has expired. Please sign in again."
	case errors.Is(err, domain.ErrRefreshSessionUnavailable):
		return "Authentication is temporarily unavailable. Please try again."
	default:
		return "We could not complete that request. Please try again."
	}
}

func authSessionResponse(account domain.User, accessToken, refreshToken string, needsVerification bool) map[string]any {
	data := map[string]any{
		"user":              dto.NewAccountResponse(account),
		"token":             accessToken,
		"needsVerification": needsVerification,
	}
	if refreshToken != "" {
		data["refreshToken"] = refreshToken
	}
	return map[string]any{"success": true, "data": data}
}
