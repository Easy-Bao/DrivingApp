package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
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
	var input dto.Credentials
	if !decode(w, r, &input) {
		return
	}
	handler.registerDecoded(w, r, input, driver)
}

func (handler *Handler) GenericRegister(w http.ResponseWriter, r *http.Request) {
	var input dto.Credentials
	if !decode(w, r, &input) {
		return
	}
	if input.Role != string(domain.Driver) && input.Role != string(domain.Passenger) {
		writeError(w, http.StatusBadRequest, "role must be passenger or driver")
		return
	}
	handler.registerDecoded(w, r, input, input.Role == string(domain.Driver))
}

func (handler *Handler) registerDecoded(w http.ResponseWriter, r *http.Request, input dto.Credentials, driver bool) {
	if !driver {
		if handler.otp == nil {
			writeError(w, http.StatusServiceUnavailable, "passenger verification is unavailable")
			return
		}
		pending, err := handler.otp.RegisterPassenger(r.Context(), toRegisterInput(input))
		if err != nil {
			status := http.StatusBadRequest
			if errors.Is(err, domain.ErrEmailTaken) {
				status = http.StatusConflict
			}
			if errors.Is(err, domain.ErrOTPUnavailable) {
				status = http.StatusServiceUnavailable
			}
			writeError(w, status, err.Error())
			return
		}
		writeJSON(w, http.StatusAccepted, map[string]any{
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
		if errors.Is(err, domain.ErrEmailTaken) {
			status = http.StatusConflict
		}
		writeError(w, status, err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"success": true, "data": map[string]any{"user": account, "token": token, "needsVerification": !account.IsVerified}})
}
func (handler *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var input dto.Credentials
	if !decode(w, r, &input) {
		return
	}
	account, token, err := handler.authenticate.Execute(r.Context(), input.Email, input.Password)
	if err != nil {
		writeError(w, http.StatusUnauthorized, domain.ErrInvalidCredentials.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "data": map[string]any{"user": account, "token": token, "needsVerification": !account.IsVerified}})
}

func (handler *Handler) RequestOTP(w http.ResponseWriter, r *http.Request) {
	if handler.otp == nil {
		writeError(w, http.StatusServiceUnavailable, "otp delivery is unavailable")
		return
	}
	var input dto.OTPRequest
	if !decode(w, r, &input) {
		return
	}
	if err := handler.otp.RequestVerification(r.Context(), input.Email); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]any{"success": true, "data": map[string]bool{"sent": true}})
}

func (handler *Handler) VerifyOTP(w http.ResponseWriter, r *http.Request) {
	if handler.otp == nil {
		writeError(w, http.StatusServiceUnavailable, "otp delivery is unavailable")
		return
	}
	var input dto.OTPVerification
	if !decode(w, r, &input) {
		return
	}

	account, token, err := handler.otp.VerifyPassenger(r.Context(), input.Email, input.Code)

	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "data": map[string]any{"verified": true, "user": account, "token": token}})
}

func (handler *Handler) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	if handler.otp == nil {
		writeError(w, http.StatusServiceUnavailable, "otp delivery is unavailable")
		return
	}
	var input dto.OTPRequest
	if !decode(w, r, &input) {
		return
	}
	if err := handler.otp.RequestPasswordReset(r.Context(), input.Email); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "data": map[string]bool{"success": true}})
}

func (handler *Handler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	if handler.otp == nil {
		writeError(w, http.StatusServiceUnavailable, "otp delivery is unavailable")
		return
	}
	var input dto.PasswordReset
	if !decode(w, r, &input) {
		return
	}
	if err := handler.otp.ResetPassword(r.Context(), input.Email, input.Code, input.NewPassword); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "message": "password reset successful"})
}

func toRegisterInput(input dto.Credentials) usecase.RegisterInput {
	return usecase.RegisterInput{Email: input.Email, Phone: input.Phone, Name: input.Name, Password: input.Password, VehicleType: input.VehicleType, PlateNumber: input.PlateNumber}
}

func decode(w http.ResponseWriter, r *http.Request, value any) bool {
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(value) != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return false
	}
	return true
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	response.JSON(w, status, value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
