package http

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
)

type Router struct {
	register     *usecase.RegisterService
	authenticate *usecase.AuthenticateService
}

func NewRouter(register *usecase.RegisterService, authenticate *usecase.AuthenticateService) *Router {
	return &Router{register: register, authenticate: authenticate}
}
func (router *Router) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/auth/passenger/register", router.passengerRegister)
	mux.HandleFunc("POST /api/v1/auth/driver/register", router.driverRegister)
	mux.HandleFunc("POST /api/v1/auth/passenger/login", router.login)
	mux.HandleFunc("POST /api/v1/auth/driver/login", router.login)
}

type credentials struct {
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Name     string `json:"name"`
	Password string `json:"password"`
}

func (router *Router) passengerRegister(w http.ResponseWriter, r *http.Request) {
	router.registerAccount(w, r, false)
}
func (router *Router) driverRegister(w http.ResponseWriter, r *http.Request) {
	router.registerAccount(w, r, true)
}
func (router *Router) registerAccount(w http.ResponseWriter, r *http.Request, driver bool) {
	var input credentials
	if !decode(w, r, &input) {
		return
	}
	var account domain.User
	var token string
	var err error
	if driver {
		account, token, err = router.register.Driver(r.Context(), toRegisterInput(input))
	} else {
		account, token, err = router.register.Passenger(r.Context(), toRegisterInput(input))
	}
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, domain.ErrEmailTaken) {
			status = http.StatusConflict
		}
		writeError(w, status, err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"user": account, "token": token})
}
func (router *Router) login(w http.ResponseWriter, r *http.Request) {
	var input credentials
	if !decode(w, r, &input) {
		return
	}
	account, token, err := router.authenticate.Execute(r.Context(), input.Email, input.Password)
	if err != nil {
		writeError(w, http.StatusUnauthorized, domain.ErrInvalidCredentials.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"user": account, "token": token})
}
func toRegisterInput(input credentials) usecase.RegisterInput {
	return usecase.RegisterInput{Email: input.Email, Phone: input.Phone, Name: input.Name, Password: input.Password}
}
func decode(w http.ResponseWriter, r *http.Request, value any) bool {
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(value) != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return false
	}
	return true
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
