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
	raw := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	if raw == r.Header.Get("Authorization") || raw == "" {
		return 0, false
	}
	subject, err := handler.verifier.Verify(raw)
	id, parseErr := strconv.Atoi(subject)
	return id, err == nil && parseErr == nil
}
func (handler *Handler) CreateRide(w http.ResponseWriter, r *http.Request) {
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
		errorJSON(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	jsonJSON(w, 201, ride)
}

func (handler *Handler) AcceptRide(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
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

func (handler *Handler) UpdateStatus(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
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

func (handler *Handler) SettleCash(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		errorJSON(w, http.StatusBadRequest, "invalid ride id")
		return
	}
	ride, err := handler.service.SettleCash(r.Context(), rideID, driverID)
	if err != nil {
		errorJSON(w, rideErrorStatus(err), err.Error())
		return
	}
	jsonJSON(w, http.StatusOK, ride)
}
func (handler *Handler) SubmitBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		errorJSON(w, 400, "invalid ride id")
		return
	}
	var input dto.SubmitBidRequest
	if json.NewDecoder(r.Body).Decode(&input) != nil || input.FareCentavos <= 0 {
		errorJSON(w, 400, "invalid fare")
		return
	}
	bid, err := handler.service.SubmitBid(r.Context(), rideID, driverID, input.FareCentavos)
	if err != nil {
		errorJSON(w, rideErrorStatus(err), err.Error())
		return
	}
	jsonJSON(w, 201, bid)
}
func (handler *Handler) AcceptBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	bidID, err := strconv.Atoi(chi.URLParam(r, "id"))
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
func (handler *Handler) GetRide(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
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

func (handler *Handler) PassengerRides(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
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

func (handler *Handler) DriverStats(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		errorJSON(w, 400, "invalid driver id")
		return
	}
	if driverID != actorID {
		errorJSON(w, 403, "forbidden")
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

func (handler *Handler) DriverTrips(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		errorJSON(w, 400, "invalid driver id")
		return
	}
	if driverID != actorID {
		errorJSON(w, 403, "forbidden")
		return
	}
	items, err := handler.service.DriverTrips(r.Context(), driverID)
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}
	jsonJSON(w, 200, items)
}

func (handler *Handler) DriverReviews(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
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

func (handler *Handler) CreateReview(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		errorJSON(w, 400, "invalid driver id")
		return
	}
	var input dto.ReviewRequest
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(&input) != nil || input.RideID <= 0 {
		errorJSON(w, 400, "invalid review")
		return
	}
	item, err := handler.service.CreateReview(r.Context(), domain.Review{RideID: input.RideID, DriverID: driverID, PassengerID: passengerID, Rating: input.Rating, Comment: input.Comment})
	if err != nil {
		errorJSON(w, 400, err.Error())
		return
	}
	jsonJSON(w, 201, item)
}

func (handler *Handler) CreatePassengerReview(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	passengerID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		errorJSON(w, 400, "invalid passenger id")
		return
	}
	var input dto.ReviewRequest
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(&input) != nil || input.RideID <= 0 {
		errorJSON(w, 400, "invalid review")
		return
	}
	item, err := handler.service.CreatePassengerReview(r.Context(), domain.PassengerReview{RideID: input.RideID, DriverID: driverID, PassengerID: passengerID, Rating: input.Rating, Comment: input.Comment})
	if err != nil {
		errorJSON(w, 400, err.Error())
		return
	}
	jsonJSON(w, 201, item)
}

func (handler *Handler) OnlineDrivers(w http.ResponseWriter, r *http.Request) {
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

func (handler *Handler) PublicDriverSummaries(w http.ResponseWriter, r *http.Request) {
	items, err := handler.service.OnlineDrivers(r.Context())
	if err != nil {
		errorJSON(w, 500, err.Error())
		return
	}

	limit := queryInt(r, "limit", 5)
	if limit == 0 {
		limit = 5
	}
	if limit > 20 {
		limit = 20
	}

	summaries := make([]domain.PublicDriverSummary, 0, min(limit, len(items)))
	for _, item := range items {
		if item.ID <= 0 {
			continue
		}
		summaries = append(summaries, domain.PublicDriverSummary{
			ID:          item.ID,
			Name:        item.Name,
			VehicleType: item.VehicleType,
			Rating:      item.Rating,
		})
		if len(summaries) == limit {
			break
		}
	}
	jsonJSON(w, 200, summaries)
}

func queryInt(r *http.Request, key string, fallback int) int {
	value, err := strconv.Atoi(r.URL.Query().Get(key))
	if err != nil || value < 0 {
		return fallback
	}
	return value
}

func (handler *Handler) Estimate(w http.ResponseWriter, r *http.Request) {
	var input dto.FareEstimateRequest
	if json.NewDecoder(r.Body).Decode(&input) != nil {
		errorJSON(w, 400, "invalid fare input")
		return
	}
	metrics, total, err := handler.service.Fare(r.Context(), input.OriginLatitude, input.OriginLongitude, input.DestinationLatitude, input.DestinationLongitude, input.DistanceKm, input.DurationMinutes)
	if err != nil {
		errorJSON(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	config := handler.service.PricingConfig()
	base := float64(config.BaseFareCentavos) / 100
	distanceCharge := metrics.DistanceKm * float64(config.PerKilometerCentavos) / 100
	timeCharge := metrics.DurationMinutes * float64(config.PerMinuteCentavos) / 100
	jsonJSON(w, 200, map[string]any{"base_fare": base, "distance_charge": distanceCharge, "time_charge": timeCharge, "surge_charge": float64(0), "fare_centavos": total, "total_fare": float64(total) / 100})
}
func (handler *Handler) FareConfigs(w http.ResponseWriter, _ *http.Request) {
	jsonJSON(w, 200, handler.service.PricingConfig().FareConfigsJSON())
}
func (handler *Handler) RatingConfig(w http.ResponseWriter, _ *http.Request) {
	jsonJSON(w, 200, handler.service.PricingConfig().RatingConfigJSON())
}
func (handler *Handler) CalculateFinal(w http.ResponseWriter, r *http.Request) {
	var input dto.FinalFareRequest
	if json.NewDecoder(r.Body).Decode(&input) != nil || input.DistanceKm < 0 || input.DurationMinutes < 0 || input.CommissionBPS < 0 || input.CommissionBPS > 10000 {
		errorJSON(w, 400, "invalid final fare input")
		return
	}
	metrics, fare, err := handler.service.Fare(r.Context(), input.OriginLatitude, input.OriginLongitude, input.DestinationLatitude, input.DestinationLongitude, input.DistanceKm, input.DurationMinutes)
	if err != nil {
		errorJSON(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	commissionBPS := handler.service.PricingConfig().PlatformCommissionBPS
	commission := fare * commissionBPS / 10000
	jsonJSON(w, 200, map[string]any{"fare_centavos": fare, "distance_km": metrics.DistanceKm, "duration_minutes": metrics.DurationMinutes, "commission_centavos": commission, "driver_payout_centavos": fare - commission})
}

func (handler *Handler) CreateSession(w http.ResponseWriter, r *http.Request) {
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

func (handler *Handler) ActiveSessions(w http.ResponseWriter, r *http.Request) {
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

func (handler *Handler) Session(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
	if err != nil {
		errorJSON(w, 400, "invalid session id")
		return
	}
	item, err := handler.service.Session(r.Context(), id)
	if err != nil {
		errorJSON(w, 404, "bid session not found")
		return
	}
	if !canViewSession(actorID, item) {
		errorJSON(w, http.StatusForbidden, "forbidden")
		return
	}
	jsonJSON(w, 200, item)
}

func (handler *Handler) Offers(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
	if err != nil {
		errorJSON(w, 400, "invalid session id")
		return
	}
	session, err := handler.service.Session(r.Context(), id)
	if err != nil || session.PassengerID != actorID {
		errorJSON(w, http.StatusForbidden, "forbidden")
		return
	}
	items, err := handler.service.Offers(r.Context(), id)
	if err != nil {
		errorJSON(w, 404, "bid session not found")
		return
	}
	jsonJSON(w, 200, items)
}

func (handler *Handler) PlaceOffer(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	sessionID, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
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

func (handler *Handler) AcceptOffer(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	sessionID, sessionErr := strconv.Atoi(chi.URLParam(r, "sessionID"))
	offerID, offerErr := strconv.Atoi(chi.URLParam(r, "offerID"))
	if sessionErr != nil || offerErr != nil {
		errorJSON(w, 400, "invalid bid id")
		return
	}
	session, offer, ride, err := handler.service.AcceptOffer(r.Context(), sessionID, offerID, passengerID)
	if err != nil {
		errorJSON(w, 409, "offer cannot be accepted")
		return
	}
	jsonJSON(w, 200, map[string]any{"session": session, "offer": offer, "ride": ride, "ride_id": ride.ID})
}

func (handler *Handler) CancelSession(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
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

func (handler *Handler) CancelOffer(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		errorJSON(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
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
	case errors.Is(err, domain.ErrRouteUnavailable):
		return 503
	case errors.Is(err, domain.ErrUnauthorizedRide), errors.Is(err, domain.ErrUnauthorizedSession):
		return 403
	case errors.Is(err, domain.ErrActiveBooking), errors.Is(err, domain.ErrDriverAtCapacity), errors.Is(err, domain.ErrDriverUnavailable):
		return 409
	case errors.Is(err, domain.ErrDuplicateBid):
		return 409
	default:
		return 500
	}
}

func safeRideError(err error) string {
	switch {
	case errors.Is(err, domain.ErrInvalidTrip):
		return "The route details are invalid."
	case errors.Is(err, domain.ErrInvalidFareOffer):
		return "The custom offer cannot be lower than the calculated minimum fare."
	case errors.Is(err, domain.ErrRouteUnavailable):
		return "The route service is temporarily unavailable."
	default:
		return "The ride request could not be completed."
	}
}

func canViewSession(actorID int, session domain.BidSession) bool {
	if session.PassengerID == actorID {
		return true
	}
	return session.TargetDriverID != nil && *session.TargetDriverID == actorID
}
