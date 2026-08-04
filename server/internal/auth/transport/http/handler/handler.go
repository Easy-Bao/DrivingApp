package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	register     *usecase.RegisterService
	authenticate *usecase.AuthenticateService
	otp          *usecase.OTPService
}

func NewHandler(register *usecase.RegisterService, authenticate *usecase.AuthenticateService, otp *usecase.OTPService) *Handler {
	return &Handler{register: register, authenticate: authenticate, otp: otp}
}
func (handler *Handler) RegisterRoutes(router chi.Router) {
	router.Post("/api/v1/auth/register", handler.genericRegister)
	router.Post("/api/v1/auth/login", handler.login)
	router.Post("/api/v1/auth/passenger/register", handler.passengerRegister)
	router.Post("/api/v1/auth/driver/register", handler.driverRegister)
	router.Post("/api/v1/auth/passenger/login", handler.login)
	router.Post("/api/v1/auth/driver/login", handler.login)
	router.Post("/api/v1/auth/passenger/otp", handler.requestOTP)
	router.Post("/api/v1/auth/passenger/verify-otp", handler.verifyOTP)
	router.Post("/api/v1/auth/passenger/forgot-password", handler.forgotPassword)
	router.Post("/api/v1/auth/passenger/reset-password", handler.resetPassword)
	// These aliases keep the public gateway contract stable for the clients
	// while the application remains the only externally reachable process.
	router.Post("/auth/passenger/register", handler.passengerRegister)
	router.Post("/auth/register", handler.genericRegister)
	router.Post("/auth/driver/register", handler.driverRegister)
	router.Post("/auth/passenger/login", handler.login)
	router.Post("/auth/login", handler.login)
	router.Post("/auth/driver/login", handler.login)
	router.Post("/auth/passenger/otp", handler.requestOTP)
	router.Post("/auth/passenger/verify-otp", handler.verifyOTP)
	router.Post("/auth/verify-otp", handler.verifyOTP)
	router.Post("/auth/forgot-password", handler.forgotPassword)
	router.Post("/auth/reset-password", handler.resetPassword)
}

func (handler *Handler) passengerRegister(w http.ResponseWriter, r *http.Request) {
	handler.registerAccount(w, r, false)
}
func (handler *Handler) driverRegister(w http.ResponseWriter, r *http.Request) {
	handler.registerAccount(w, r, true)
}
func (handler *Handler) registerAccount(w http.ResponseWriter, r *http.Request, driver bool) {
	var input dto.Credentials
	if !decode(w, r, &input) {
		return
	}
	handler.registerDecoded(w, r, input, driver)
}

func (handler *Handler) genericRegister(w http.ResponseWriter, r *http.Request) {
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
func (handler *Handler) login(w http.ResponseWriter, r *http.Request) {
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

func (handler *Handler) requestOTP(w http.ResponseWriter, r *http.Request) {
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

func (handler *Handler) verifyOTP(w http.ResponseWriter, r *http.Request) {
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

func (handler *Handler) forgotPassword(w http.ResponseWriter, r *http.Request) {
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

func (handler *Handler) resetPassword(w http.ResponseWriter, r *http.Request) {
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
