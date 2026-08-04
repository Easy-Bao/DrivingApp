package http

import (
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
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
	mux.HandleFunc("POST /api/v1/rides", router.createRide)
	mux.HandleFunc("POST /api/v1/rides/{id}/bids", router.submitBid)
	mux.HandleFunc("POST /api/v1/bids/{id}/accept", router.acceptBid)
	mux.HandleFunc("GET /api/v1/rides/{id}", router.getRide)
	mux.HandleFunc("POST /api/v1/fares/estimate", router.estimate)
}
func (router *Router) identity(r *http.Request) (int, bool) {
	raw := r.Header.Get("Authorization")
	if len(raw) < 7 {
		return 0, false
	}
	subject, err := router.verifier.Verify(raw[7:])
	id, parseErr := strconv.Atoi(subject)
	return id, err == nil && parseErr == nil
}
func (router *Router) createRide(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := router.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	var input struct {
		FareCentavos int64 `json:"fare_centavos"`
	}
	if json.NewDecoder(r.Body).Decode(&input) != nil || input.FareCentavos < 0 {
		errorJSON(w, 400, "invalid fare")
		return
	}
	ride, err := router.service.CreateRide(r.Context(), passengerID, input.FareCentavos)
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 201, ride)
}
func (router *Router) submitBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := router.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid ride id")
		return
	}
	var input struct {
		FareCentavos int64 `json:"fare_centavos"`
	}
	if json.NewDecoder(r.Body).Decode(&input) != nil || input.FareCentavos < 0 {
		errorJSON(w, 400, "invalid fare")
		return
	}
	bid, err := router.service.SubmitBid(r.Context(), rideID, driverID, input.FareCentavos)
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 201, bid)
}
func (router *Router) acceptBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := router.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	bidID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid bid id")
		return
	}
	bid, ride, err := router.service.AcceptBid(r.Context(), bidID, driverID)
	if err != nil {
		errorJSON(w, 409, "bid cannot be accepted")
		return
	}
	jsonJSON(w, 200, map[string]any{"bid": bid, "ride": ride})
}
func (router *Router) getRide(w http.ResponseWriter, r *http.Request) {
	if _, ok := router.identity(r); !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid ride id")
		return
	}
	ride, err := router.service.Get(r.Context(), id)
	if err != nil {
		errorJSON(w, 404, "ride not found")
		return
	}
	jsonJSON(w, 200, ride)
}
func (router *Router) estimate(w http.ResponseWriter, r *http.Request) {
	var input struct{ DistanceKm, DurationMinutes float64 }
	if json.NewDecoder(r.Body).Decode(&input) != nil {
		errorJSON(w, 400, "invalid fare input")
		return
	}
	jsonJSON(w, 200, map[string]any{"fare_centavos": usecase.CalculateFare(input.DistanceKm, input.DurationMinutes)})
}
func jsonJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
func errorJSON(w http.ResponseWriter, status int, message string) {
	jsonJSON(w, status, map[string]string{"error": message})
}
