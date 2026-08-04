package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
)

type Handler struct {
	service  *usecase.Service
	verifier *token.Verifier
}

func NewHandler(service *usecase.Service, verifier *token.Verifier) *Handler {
	return &Handler{service: service, verifier: verifier}
}
func (handler *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/rides", handler.createRide)
	mux.HandleFunc("POST /api/v1/rides/{id}/accept", handler.acceptRide)
	mux.HandleFunc("POST /api/v1/rides/{id}/status", handler.updateStatus)
	mux.HandleFunc("POST /api/v1/rides/{id}/bids", handler.submitBid)
	mux.HandleFunc("POST /api/v1/bids/{id}/accept", handler.acceptBid)
	mux.HandleFunc("GET /api/v1/rides/{id}", handler.getRide)
	mux.HandleFunc("GET /api/v1/passengers/{id}/rides", handler.passengerRides)
	mux.HandleFunc("GET /api/v1/drivers/online", handler.onlineDrivers)
	mux.HandleFunc("GET /api/v1/drivers/{id}/stats", handler.driverStats)
	mux.HandleFunc("GET /api/v1/drivers/{id}/trips", handler.driverTrips)
	mux.HandleFunc("GET /api/v1/drivers/{id}/reviews", handler.driverReviews)
	mux.HandleFunc("POST /api/v1/drivers/{id}/reviews", handler.createReview)
	mux.HandleFunc("POST /api/v1/fares/estimate", handler.estimate)
	mux.HandleFunc("GET /api/v1/fares/configs", handler.fareConfigs)
	mux.HandleFunc("GET /api/v1/fares/rating-config", handler.ratingConfig)
	mux.HandleFunc("POST /api/v1/fares/calculate-final", handler.calculateFinal)
	mux.HandleFunc("POST /api/v1/bids/fare", handler.estimate)
	mux.HandleFunc("POST /api/v1/bids", handler.createSession)
	mux.HandleFunc("GET /api/v1/bids/active", handler.activeSessions)
	mux.HandleFunc("GET /api/v1/bids/{sessionID}", handler.session)
	mux.HandleFunc("GET /api/v1/bids/{sessionID}/offers", handler.offers)
	mux.HandleFunc("POST /api/v1/bids/{sessionID}/offer", handler.placeOffer)
	mux.HandleFunc("POST /api/v1/bids/{sessionID}/offers/{offerID}/accept", handler.acceptOffer)
	mux.HandleFunc("POST /api/v1/bids/{sessionID}/cancel", handler.cancelSession)
	mux.HandleFunc("POST /api/v1/bids/{sessionID}/cancel-offer", handler.cancelOffer)
	mux.HandleFunc("POST /rides", handler.createRide)
	mux.HandleFunc("POST /rides/{id}/accept", handler.acceptRide)
	mux.HandleFunc("POST /rides/{id}/status", handler.updateStatus)
	mux.HandleFunc("GET /rides/{id}", handler.getRide)
	mux.HandleFunc("GET /passengers/{id}/rides", handler.passengerRides)
	mux.HandleFunc("GET /drivers/online", handler.onlineDrivers)
	mux.HandleFunc("GET /drivers/{id}/stats", handler.driverStats)
	mux.HandleFunc("GET /drivers/{id}/trips", handler.driverTrips)
	mux.HandleFunc("GET /drivers/{id}/reviews", handler.driverReviews)
	mux.HandleFunc("POST /drivers/{id}/reviews", handler.createReview)
	mux.HandleFunc("POST /bids/fare", handler.estimate)
	mux.HandleFunc("POST /bids", handler.createSession)
	mux.HandleFunc("GET /bids/active", handler.activeSessions)
	mux.HandleFunc("GET /bids/{sessionID}", handler.session)
	mux.HandleFunc("GET /bids/{sessionID}/offers", handler.offers)
	mux.HandleFunc("POST /bids/{sessionID}/offer", handler.placeOffer)
	mux.HandleFunc("POST /bids/{sessionID}/offers/{offerID}/accept", handler.acceptOffer)
	mux.HandleFunc("POST /bids/{sessionID}/cancel", handler.cancelSession)
	mux.HandleFunc("POST /bids/{sessionID}/cancel-offer", handler.cancelOffer)
	mux.HandleFunc("POST /fares/estimate", handler.estimate)
}
func (handler *Handler) identity(r *http.Request) (int, bool) {
	raw := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	if raw == r.Header.Get("Authorization") || raw == "" {
		return 0, false
	}
	subject, err := handler.verifier.Verify(raw)
	id, parseErr := strconv.Atoi(subject)
	return id, err == nil && parseErr == nil
}
func (handler *Handler) createRide(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	var input dto.CreateRideRequest
	if json.NewDecoder(r.Body).Decode(&input) != nil || input.FareCentavos < 0 {
		errorJSON(w, 400, "invalid fare")
		return
	}
	ride, err := handler.service.CreateRideWithDetails(r.Context(), domainRide(passengerID, input))
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 201, ride)
}

func (handler *Handler) acceptRide(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid ride id")
		return
	}
	item, err := handler.service.AcceptRide(r.Context(), rideID, driverID)
	if err != nil {
		errorJSON(w, 409, "ride cannot be accepted")
		return
	}
	jsonJSON(w, 200, item)
}

func (handler *Handler) updateStatus(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid ride id")
		return
	}
	var input dto.StatusRequest
	if json.NewDecoder(r.Body).Decode(&input) != nil || input.Status == "" {
		errorJSON(w, 400, "invalid ride status")
		return
	}
	item, err := handler.service.UpdateStatus(r.Context(), rideID, actorID, input.Status)
	if err != nil {
		errorJSON(w, 409, err.Error())
		return
	}
	jsonJSON(w, 200, item)
}
func (handler *Handler) submitBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid ride id")
		return
	}
	var input dto.SubmitBidRequest
	if json.NewDecoder(r.Body).Decode(&input) != nil || input.FareCentavos < 0 {
		errorJSON(w, 400, "invalid fare")
		return
	}
	bid, err := handler.service.SubmitBid(r.Context(), rideID, driverID, input.FareCentavos)
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 201, bid)
}
func (handler *Handler) acceptBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	bidID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid bid id")
		return
	}
	bid, ride, err := handler.service.AcceptBid(r.Context(), bidID, driverID)
	if err != nil {
		errorJSON(w, 409, "bid cannot be accepted")
		return
	}
	jsonJSON(w, 200, map[string]any{"bid": bid, "ride": ride})
}
func (handler *Handler) getRide(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid ride id")
		return
	}
	ride, err := handler.service.Get(r.Context(), id)
	if err != nil {
		errorJSON(w, 404, "ride not found")
		return
	}
	if ride.PassengerID != actorID && (ride.DriverID == nil || *ride.DriverID != actorID) {
		errorJSON(w, 403, "forbidden")
		return
	}
	jsonJSON(w, 200, ride)
}

func (handler *Handler) passengerRides(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil || targetID != actorID {
		errorJSON(w, 403, "forbidden")
		return
	}
	items, err := handler.service.PassengerRides(r.Context(), targetID)
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 200, items)
}

func (handler *Handler) driverStats(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid driver id")
		return
	}
	stats, err := handler.service.DriverStats(r.Context(), driverID)
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	// Keep both naming styles while clients finish their API contract cutover.
	jsonJSON(w, 200, map[string]any{"driver_id": stats.DriverID, "total_trips": stats.TotalTrips, "completed_trips": stats.CompletedTrips, "active_trips": stats.ActiveTrips, "total_fare_centavos": stats.TotalFare, "average_rating": stats.AverageRating, "totalTrips": stats.TotalTrips, "completedTrips": stats.CompletedTrips})
}

func (handler *Handler) driverTrips(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid driver id")
		return
	}
	items, err := handler.service.DriverTrips(r.Context(), driverID)
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 200, items)
}

func (handler *Handler) driverReviews(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid driver id")
		return
	}
	limit := queryInt(r, "limit", 20)
	if limit > 100 {
		limit = 100
	}
	items, err := handler.service.DriverReviews(r.Context(), driverID, limit, queryInt(r, "offset", 0))
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 200, items)
}

func (handler *Handler) createReview(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		errorJSON(w, 400, "invalid driver id")
		return
	}
	var input dto.ReviewRequest
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(&input) != nil {
		errorJSON(w, 400, "invalid review")
		return
	}
	item, err := handler.service.CreateReview(r.Context(), domain.Review{DriverID: driverID, PassengerID: passengerID, PassengerName: input.PassengerName, Rating: input.Rating, Comment: input.Comment})
	if err != nil {
		errorJSON(w, 400, err.Error())
		return
	}
	jsonJSON(w, 201, item)
}

func (handler *Handler) onlineDrivers(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	items, err := handler.service.OnlineDrivers(r.Context())
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 200, items)
}

func queryInt(r *http.Request, key string, fallback int) int {
	value, err := strconv.Atoi(r.URL.Query().Get(key))
	if err != nil || value < 0 {
		return fallback
	}
	return value
}
func (handler *Handler) estimate(w http.ResponseWriter, r *http.Request) {
	var input dto.FareEstimateRequest
	if json.NewDecoder(r.Body).Decode(&input) != nil {
		errorJSON(w, 400, "invalid fare input")
		return
	}
	if input.DistanceKm < 0 || input.DurationMinutes < 0 {
		errorJSON(w, 400, "invalid fare input")
		return
	}
	base := int64(2500)
	distanceCharge := int64(input.DistanceKm * 100)
	timeCharge := int64(input.DurationMinutes * 50)
	total := usecase.CalculateFare(input.DistanceKm, input.DurationMinutes)
	jsonJSON(w, 200, map[string]any{"base_fare": float64(base) / 100, "distance_charge": float64(distanceCharge) / 100, "time_charge": float64(timeCharge) / 100, "surge_charge": float64(0), "fare_centavos": total, "total_fare": float64(total) / 100})
}
func (handler *Handler) fareConfigs(w http.ResponseWriter, _ *http.Request) {
	jsonJSON(w, 200, map[string]any{"base_fare_centavos": int64(2500), "per_kilometer_centavos": int64(100), "per_minute_centavos": int64(50)})
}
func (handler *Handler) ratingConfig(w http.ResponseWriter, _ *http.Request) {
	jsonJSON(w, 200, map[string]any{"minimum_rating": 1, "maximum_rating": 5})
}
func (handler *Handler) calculateFinal(w http.ResponseWriter, r *http.Request) {
	var input dto.FinalFareRequest
	if json.NewDecoder(r.Body).Decode(&input) != nil || input.DistanceKm < 0 || input.DurationMinutes < 0 || input.CommissionBPS < 0 || input.CommissionBPS > 10000 {
		errorJSON(w, 400, "invalid final fare input")
		return
	}
	fare := usecase.CalculateFare(input.DistanceKm, input.DurationMinutes)
	commissionBPS := int64(1500)
	commission := fare * commissionBPS / 10000
	jsonJSON(w, 200, map[string]any{"fare_centavos": fare, "commission_centavos": commission, "driver_payout_centavos": fare - commission})
}

func (handler *Handler) createSession(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	var input dto.BidSessionRequest
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(&input) != nil {
		errorJSON(w, 400, "invalid bid session")
		return
	}
	session, err := handler.service.CreateSession(r.Context(), domain.BidSession{PassengerID: passengerID, RideType: input.RideType, PickupLatitude: input.PickupLatitude, PickupLongitude: input.PickupLongitude, PickupName: input.PickupName, DropoffLatitude: input.DropoffLatitude, DropoffLongitude: input.DropoffLongitude, DropoffName: input.DropoffName, DistanceKm: input.DistanceKm, DurationMinutes: input.DurationMinutes, TargetDriverID: input.TargetDriverID, CustomFareCentavos: input.CustomFareCentavos})
	if err != nil {
		errorJSON(w, rideErrorStatus(err), err.Error())
		return
	}
	jsonJSON(w, 201, session)
}

func (handler *Handler) activeSessions(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	sessions, err := handler.service.ActiveSessions(r.Context(), &driverID)
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 200, sessions)
}

func (handler *Handler) session(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(r.PathValue("sessionID"))
	if err != nil {
		errorJSON(w, 400, "invalid session id")
		return
	}
	item, err := handler.service.Session(r.Context(), id)
	if err != nil {
		errorJSON(w, 404, "bid session not found")
		return
	}
	jsonJSON(w, 200, item)
}

func (handler *Handler) offers(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(r.PathValue("sessionID"))
	if err != nil {
		errorJSON(w, 400, "invalid session id")
		return
	}
	items, err := handler.service.Offers(r.Context(), id)
	if err != nil {
		errorJSON(w, 404, "bid session not found")
		return
	}
	jsonJSON(w, 200, items)
}

func (handler *Handler) placeOffer(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	sessionID, err := strconv.Atoi(r.PathValue("sessionID"))
	if err != nil {
		errorJSON(w, 400, "invalid session id")
		return
	}
	var input dto.BidOfferRequest
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(&input) != nil {
		errorJSON(w, 400, "invalid bid offer")
		return
	}
	fare := input.ProposedFareCentavos
	if fare == 0 && input.OfferPrice > 0 {
		fare = int64(input.OfferPrice * 100)
	}
	offer, err := handler.service.PlaceOffer(r.Context(), domain.BidOffer{SessionID: sessionID, DriverID: driverID, DriverName: input.DriverName, PlateNumber: input.PlateNumber, VehicleType: input.VehicleType, ProposedFareCentavos: fare})
	if err != nil {
		errorJSON(w, 409, err.Error())
		return
	}
	jsonJSON(w, 201, offer)
}

func (handler *Handler) acceptOffer(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	sessionID, sessionErr := strconv.Atoi(r.PathValue("sessionID"))
	offerID, offerErr := strconv.Atoi(r.PathValue("offerID"))
	if sessionErr != nil || offerErr != nil {
		errorJSON(w, 400, "invalid bid id")
		return
	}
	session, offer, ride, err := handler.service.AcceptOffer(r.Context(), sessionID, offerID, driverID)
	if err != nil {
		errorJSON(w, 409, "offer cannot be accepted")
		return
	}
	jsonJSON(w, 200, map[string]any{"session": session, "offer": offer, "ride": ride, "ride_id": ride.ID})
}

func (handler *Handler) cancelSession(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(r.PathValue("sessionID"))
	if err != nil {
		errorJSON(w, 400, "invalid session id")
		return
	}
	item, err := handler.service.CancelSession(r.Context(), id, passengerID)
	if err != nil {
		errorJSON(w, 409, "session cannot be canceled")
		return
	}
	jsonJSON(w, 200, item)
}

func (handler *Handler) cancelOffer(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(r.PathValue("sessionID"))
	if err != nil {
		errorJSON(w, 400, "invalid session id")
		return
	}
	item, err := handler.service.CancelOffer(r.Context(), id, driverID)
	if err != nil {
		errorJSON(w, 404, "offer not found")
		return
	}
	jsonJSON(w, 200, item)
}

func domainRide(passengerID int, input dto.CreateRideRequest) domain.Ride {
	rideType := input.RideType
	if rideType == "" {
		rideType = "solo"
	}
	return domain.Ride{PassengerID: passengerID, FareCentavos: input.FareCentavos, Status: "requested", RideType: rideType, PickupLatitude: input.PickupLatitude, PickupLongitude: input.PickupLongitude, PickupName: input.PickupName, DropoffLatitude: input.DropoffLatitude, DropoffLongitude: input.DropoffLongitude, DropoffName: input.DropoffName, DistanceKm: input.DistanceKm, DurationMinutes: input.DurationMinutes}
}
func jsonJSON(w http.ResponseWriter, status int, value any) {
	response.JSON(w, status, value)
}
func errorJSON(w http.ResponseWriter, status int, message string) {
	code := "request_failed"
	switch status {
	case 400:
		code = "validation_error"
	case 401:
		code = "unauthorized"
	case 403:
		code = "forbidden"
	case 404:
		code = "not_found"
	case 409:
		code = "conflict"
	case 429:
		code = "rate_limited"
	case 500:
		code = "internal_error"
	}
	jsonJSON(w, status, map[string]string{"code": code, "error": message, "message": message})
}

func rideErrorStatus(err error) int {
	switch {
	case errors.Is(err, domain.ErrInvalidTrip), errors.Is(err, domain.ErrInvalidFareOffer):
		return 400
	case errors.Is(err, domain.ErrUnauthorizedRide), errors.Is(err, domain.ErrUnauthorizedSession):
		return 403
	case errors.Is(err, domain.ErrActiveBooking), errors.Is(err, domain.ErrDriverAtCapacity), errors.Is(err, domain.ErrDriverUnavailable):
		return 409
	default:
		return 500
	}
}
