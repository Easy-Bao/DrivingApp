package http

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/http/dto"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service  *application.RideService
	verifier *security.TokenManager
}

func NewHandler(service *application.RideService, verifier *security.TokenManager) *Handler {
	return &Handler{service: service, verifier: verifier}
}
func (handler *Handler) identity(r *http.Request) (int, bool) {
	return middleware.AuthenticatedUserID(r, handler.verifier)
}
func (handler *Handler) CreateRide(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	var input dto.CreateRideRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.FareCentavos < 0 {
		response.Error(w, 400, "invalid fare")
		return
	}
	ride, err := handler.service.CreateRideWithDetails(r.Context(), domainRide(passengerID, input))
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, 201, ride)
}

func (handler *Handler) AcceptRide(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid ride id")
		return
	}
	item, err := handler.service.AcceptRide(r.Context(), rideID, driverID)
	if err != nil {
		response.Error(w, 409, "ride cannot be accepted")
		return
	}
	response.JSON(w, 200, item)
}

func (handler *Handler) UpdateStatus(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid ride id")
		return
	}
	var input dto.StatusRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.Status == "" {
		response.Error(w, 400, "invalid ride status")
		return
	}
	item, err := handler.service.UpdateStatus(r.Context(), rideID, actorID, input.Status)
	if err != nil {
		response.Error(w, 409, safeRideError(err))
		return
	}
	response.JSON(w, 200, item)
}

func (handler *Handler) SettleCash(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid ride id")
		return
	}
	ride, err := handler.service.SettleCash(r.Context(), rideID, driverID)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, ride)
}
func (handler *Handler) SubmitBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid ride id")
		return
	}
	var input dto.SubmitBidRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.FareCentavos <= 0 {
		response.Error(w, 400, "invalid fare")
		return
	}
	bid, err := handler.service.SubmitBid(r.Context(), rideID, driverID, input.FareCentavos)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, 201, bid)
}
func (handler *Handler) AcceptBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	bidID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid bid id")
		return
	}
	bid, ride, err := handler.service.AcceptBid(r.Context(), bidID, driverID)
	if err != nil {
		response.Error(w, 409, "bid cannot be accepted")
		return
	}
	response.JSON(w, 200, map[string]any{"bid": bid, "ride": ride})
}
func (handler *Handler) GetRide(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid ride id")
		return
	}
	ride, err := handler.service.Get(r.Context(), id)
	if err != nil {
		response.Error(w, 404, "ride not found")
		return
	}
	if ride.PassengerID != actorID && (ride.DriverID == nil || *ride.DriverID != actorID) {
		response.Error(w, 403, "forbidden")
		return
	}
	response.JSON(w, 200, ride)
}

func (handler *Handler) Counterparty(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || rideID <= 0 {
		response.Error(w, http.StatusBadRequest, "invalid ride id")
		return
	}
	result, err := handler.service.Counterparty(r.Context(), rideID, actorID)
	if err != nil {
		switch {
		case errors.Is(err, domain.ErrUnauthorizedRide):
			response.Error(w, http.StatusForbidden, "forbidden")
		case errors.Is(err, domain.ErrCounterpartyUnavailable):
			response.Error(w, http.StatusConflict, "ride counterparty is unavailable")
		default:
			response.Error(w, http.StatusNotFound, "ride counterparty not found")
		}
		return
	}
	response.JSON(w, http.StatusOK, result)
}

func (handler *Handler) PassengerRides(w http.ResponseWriter, r *http.Request) {
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
	page, err := sharedrequest.ParseOffsetPagination(r.URL.Query(), 25, 100)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid pagination")
		return
	}
	items, err := handler.service.PassengerRides(r.Context(), targetID, domain.TripHistoryQuery{
		Limit: page.Limit, Offset: page.Offset,
	})
	if err != nil {
		response.Error(w, 500, "Your trip history is temporarily unavailable.")
		return
	}
	response.JSON(w, 200, response.NewOffsetPage(items, page.Limit, page.Offset))
}

func (handler *Handler) PassengerActivitySummary(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || targetID != actorID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	summary, err := handler.service.PassengerActivitySummary(r.Context(), targetID)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, "Passenger activity is temporarily unavailable.")
		return
	}
	response.JSON(w, http.StatusOK, summary)
}

func (handler *Handler) DriverStats(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid driver id")
		return
	}
	if driverID != actorID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	stats, err := handler.service.DriverStats(r.Context(), driverID)
	if err != nil {
		response.Error(w, 500, "Driver statistics are temporarily unavailable.")
		return
	}
	response.JSON(w, 200, stats)
}

func (handler *Handler) DriverEarnings(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || driverID != actorID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	summary, err := handler.service.DriverEarnings(r.Context(), driverID)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, "Driver earnings are temporarily unavailable.")
		return
	}
	response.JSON(w, http.StatusOK, summary)
}

func (handler *Handler) DriverTrips(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid driver id")
		return
	}
	if driverID != actorID {
		response.Error(w, 403, "forbidden")
		return
	}
	activeOnly := false
	defaultLimit := 25
	maxLimit := 100
	switch r.URL.Query().Get("scope") {
	case "", "all":
	case "active":
		activeOnly = true
		defaultLimit = 10
		maxLimit = 20
	default:
		response.Error(w, http.StatusBadRequest, "invalid trip scope")
		return
	}
	page, err := sharedrequest.ParseOffsetPagination(r.URL.Query(), defaultLimit, maxLimit)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid pagination")
		return
	}
	items, err := handler.service.DriverTrips(r.Context(), driverID, domain.TripHistoryQuery{
		Limit: page.Limit, Offset: page.Offset, ActiveOnly: activeOnly,
	})
	if err != nil {
		response.Error(w, 500, "Driver trip history is temporarily unavailable.")
		return
	}
	response.JSON(w, 200, response.NewOffsetPage(items, page.Limit, page.Offset))
}

func (handler *Handler) DriverReviews(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid driver id")
		return
	}
	page, err := sharedrequest.ParseOffsetPagination(r.URL.Query(), 20, 100)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid pagination")
		return
	}
	items, err := handler.service.DriverReviews(r.Context(), driverID, page.Limit, page.Offset)
	if err != nil {
		response.Error(w, 500, "Driver reviews are temporarily unavailable.")
		return
	}
	response.JSON(w, 200, items)
}

func (handler *Handler) CreateReview(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid driver id")
		return
	}
	var input dto.ReviewRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.RideID <= 0 {
		response.Error(w, 400, "invalid review")
		return
	}
	item, err := handler.service.CreateReview(r.Context(), domain.Review{RideID: input.RideID, DriverID: driverID, PassengerID: passengerID, Rating: input.Rating, Comment: input.Comment})
	if err != nil {
		response.Error(w, 400, safeRideError(err))
		return
	}
	response.JSON(w, 201, item)
}

func (handler *Handler) CreatePassengerReview(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	passengerID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, 400, "invalid passenger id")
		return
	}
	var input dto.ReviewRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.RideID <= 0 {
		response.Error(w, 400, "invalid review")
		return
	}
	item, err := handler.service.CreatePassengerReview(r.Context(), domain.PassengerReview{RideID: input.RideID, DriverID: driverID, PassengerID: passengerID, Rating: input.Rating, Comment: input.Comment})
	if err != nil {
		response.Error(w, 400, safeRideError(err))
		return
	}
	response.JSON(w, 201, item)
}

func (handler *Handler) OnlineDrivers(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	driverIDs, err := driverIDsFromQuery(r)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "driver ids are required")
		return
	}
	items, err := handler.service.OnlineDrivers(r.Context(), driverIDs)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, "driver availability unavailable")
		return
	}
	response.JSON(w, 200, items)
}

func (handler *Handler) PublicDriverSummaries(w http.ResponseWriter, r *http.Request) {
	limit := 5
	if r.URL.Query().Has("limit") {
		var err error
		limit, err = strconv.Atoi(r.URL.Query().Get("limit"))
		if err != nil || limit <= 0 || limit > 20 {
			response.Error(w, http.StatusBadRequest, "invalid limit")
			return
		}
	}
	summaries, err := handler.service.PublicDriverSummaries(r.Context(), limit)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, "driver availability unavailable")
		return
	}
	response.JSON(w, 200, summaries)
}

func driverIDsFromQuery(request *http.Request) ([]int, error) {
	values := strings.Split(request.URL.Query().Get("ids"), ",")
	if len(values) == 0 || len(values) > 20 {
		return nil, errors.New("invalid driver ids")
	}
	ids := make([]int, 0, len(values))
	seen := make(map[int]struct{}, len(values))
	for _, value := range values {
		id, err := strconv.Atoi(strings.TrimSpace(value))
		if err != nil || id <= 0 {
			return nil, errors.New("invalid driver id")
		}
		if _, exists := seen[id]; exists {
			continue
		}
		seen[id] = struct{}{}
		ids = append(ids, id)
	}
	if len(ids) == 0 {
		return nil, errors.New("driver ids are required")
	}
	return ids, nil
}

func (handler *Handler) Estimate(w http.ResponseWriter, r *http.Request) {
	var input dto.FareEstimateRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, 400, "invalid fare input")
		return
	}
	metrics, total, err := handler.service.Fare(r.Context(), input.OriginLatitude, input.OriginLongitude, input.DestinationLatitude, input.DestinationLongitude, input.DistanceKm, input.DurationMinutes)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	config := handler.service.PricingConfig()
	base := float64(config.BaseFareCentavos) / 100
	distanceCharge := metrics.DistanceKm * float64(config.PerKilometerCentavos) / 100
	timeCharge := metrics.DurationMinutes * float64(config.PerMinuteCentavos) / 100
	response.JSON(w, 200, map[string]any{"base_fare": base, "distance_charge": distanceCharge, "time_charge": timeCharge, "surge_charge": float64(0), "fare_centavos": total, "total_fare": float64(total) / 100})
}
func (handler *Handler) FareConfigs(w http.ResponseWriter, _ *http.Request) {
	response.JSON(w, 200, handler.service.PricingConfig().FareConfigsJSON())
}
func (handler *Handler) RatingConfig(w http.ResponseWriter, _ *http.Request) {
	response.JSON(w, 200, handler.service.PricingConfig().RatingConfigJSON())
}
func (handler *Handler) CalculateFinal(w http.ResponseWriter, r *http.Request) {
	var input dto.FinalFareRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.DistanceKm < 0 || input.DurationMinutes < 0 || input.CommissionBPS < 0 || input.CommissionBPS > 10000 {
		response.Error(w, 400, "invalid final fare input")
		return
	}
	metrics, fare, err := handler.service.Fare(r.Context(), input.OriginLatitude, input.OriginLongitude, input.DestinationLatitude, input.DestinationLongitude, input.DistanceKm, input.DurationMinutes)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	commissionBPS := handler.service.PricingConfig().PlatformCommissionBPS
	commission := fare * commissionBPS / 10000
	response.JSON(w, 200, map[string]any{"fare_centavos": fare, "distance_km": metrics.DistanceKm, "duration_minutes": metrics.DurationMinutes, "commission_centavos": commission, "driver_payout_centavos": fare - commission})
}

func (handler *Handler) CreateSession(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	var input dto.BidSessionRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, 400, "invalid bid session")
		return
	}
	session, err := handler.service.CreateSession(r.Context(), domain.BidSession{PassengerID: passengerID, RideType: input.RideType, PickupLatitude: input.PickupLatitude, PickupLongitude: input.PickupLongitude, PickupName: input.PickupName, DropoffLatitude: input.DropoffLatitude, DropoffLongitude: input.DropoffLongitude, DropoffName: input.DropoffName, PassengerNote: strings.TrimSpace(input.PassengerNote), DistanceKm: input.DistanceKm, DurationMinutes: input.DurationMinutes, TargetDriverID: input.TargetDriverID, CustomFareCentavos: input.CustomFareCentavos})
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, 201, session)
}

func (handler *Handler) ActiveSessions(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	sessions, err := handler.service.ActiveSessions(r.Context(), &driverID)
	if err != nil {
		response.Error(w, 500, "Incoming ride requests are temporarily unavailable.")
		return
	}
	response.JSON(w, 200, sessions)
}

func (handler *Handler) Session(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
	if err != nil {
		response.Error(w, 400, "invalid session id")
		return
	}
	item, err := handler.service.Session(r.Context(), id)
	if err != nil {
		response.Error(w, 404, "bid session not found")
		return
	}
	if !canViewSession(actorID, item) {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	response.JSON(w, 200, item)
}

func (handler *Handler) Offers(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
	if err != nil {
		response.Error(w, 400, "invalid session id")
		return
	}
	session, err := handler.service.Session(r.Context(), id)
	if err != nil || session.PassengerID != actorID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	items, err := handler.service.Offers(r.Context(), id)
	if err != nil {
		response.Error(w, 404, "bid session not found")
		return
	}
	response.JSON(w, 200, items)
}

func (handler *Handler) PlaceOffer(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	sessionID, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
	if err != nil {
		response.Error(w, 400, "invalid session id")
		return
	}
	var input dto.BidOfferRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, 400, "invalid bid offer")
		return
	}
	fare := input.ProposedFareCentavos
	if fare == 0 && input.OfferPrice > 0 {
		fare = int64(input.OfferPrice * 100)
	}
	offer, err := handler.service.PlaceOffer(r.Context(), domain.BidOffer{SessionID: sessionID, DriverID: driverID, DriverName: input.DriverName, PlateNumber: input.PlateNumber, VehicleType: input.VehicleType, ProposedFareCentavos: fare})
	if err != nil {
		response.Error(w, 409, safeRideError(err))
		return
	}
	response.JSON(w, 201, offer)
}

func (handler *Handler) AcceptOffer(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	sessionID, sessionErr := strconv.Atoi(chi.URLParam(r, "sessionID"))
	offerID, offerErr := strconv.Atoi(chi.URLParam(r, "offerID"))
	if sessionErr != nil || offerErr != nil {
		response.Error(w, 400, "invalid bid id")
		return
	}
	session, offer, ride, err := handler.service.AcceptOffer(r.Context(), sessionID, offerID, passengerID)
	if err != nil {
		response.Error(w, 409, "offer cannot be accepted")
		return
	}
	response.JSON(w, 200, map[string]any{"session": session, "offer": offer, "ride": ride, "ride_id": ride.ID})
}

func (handler *Handler) CancelSession(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
	if err != nil {
		response.Error(w, 400, "invalid session id")
		return
	}
	item, err := handler.service.CancelSession(r.Context(), id, passengerID)
	if err != nil {
		response.Error(w, 409, "session cannot be canceled")
		return
	}
	response.JSON(w, 200, item)
}

func (handler *Handler) CancelOffer(w http.ResponseWriter, r *http.Request) {
	driverID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "sessionID"))
	if err != nil {
		response.Error(w, 400, "invalid session id")
		return
	}
	item, err := handler.service.CancelOffer(r.Context(), id, driverID)
	if err != nil {
		response.Error(w, 404, "offer not found")
		return
	}
	response.JSON(w, 200, item)
}

func domainRide(passengerID int, input dto.CreateRideRequest) domain.Ride {
	rideType := input.RideType
	if rideType == "" {
		rideType = "solo"
	}
	return domain.Ride{PassengerID: passengerID, FareCentavos: input.FareCentavos, Status: "requested", RideType: rideType, PickupLatitude: input.PickupLatitude, PickupLongitude: input.PickupLongitude, PickupName: input.PickupName, DropoffLatitude: input.DropoffLatitude, DropoffLongitude: input.DropoffLongitude, DropoffName: input.DropoffName, DistanceKm: input.DistanceKm, DurationMinutes: input.DurationMinutes}
}

func rideErrorStatus(err error) int {
	switch {
	case errors.Is(err, domain.ErrInvalidTrip), errors.Is(err, domain.ErrInvalidFareOffer):
		return 400
	case errors.Is(err, domain.ErrRouteUnavailable):
		return 503
	case errors.Is(err, domain.ErrUnauthorizedRide), errors.Is(err, domain.ErrUnauthorizedSession):
		return 403
	case errors.Is(err, domain.ErrActiveBooking),
		errors.Is(err, domain.ErrDriverAtCapacity),
		errors.Is(err, domain.ErrDriverUnavailable),
		errors.Is(err, domain.ErrDuplicateBid):
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
	case errors.Is(err, domain.ErrActiveBooking):
		return "You already have an active ride."
	case errors.Is(err, domain.ErrDriverAtCapacity):
		return "This driver cannot accept another passenger right now."
	case errors.Is(err, domain.ErrUnauthorizedRide), errors.Is(err, domain.ErrUnauthorizedSession):
		return "You do not have access to this ride."
	case errors.Is(err, domain.ErrDriverUnavailable):
		return "This driver is no longer available."
	case errors.Is(err, domain.ErrDuplicateBid):
		return "You already sent an offer for this ride."
	case errors.Is(err, domain.ErrInvalidStatusTransition):
		return "That ride status cannot be changed right now."
	case errors.Is(err, domain.ErrReviewNotAllowed):
		return "Reviews are available after a completed ride."
	case errors.Is(err, domain.ErrReviewAlreadySubmitted):
		return "You already submitted a review for this ride."
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
