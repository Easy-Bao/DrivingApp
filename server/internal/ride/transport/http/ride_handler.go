package http

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	application "github.com/Easy-Bao/DrivingApp/server/internal/ride/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service  *application.RideService
	verifier *security.TokenManager
}

type Dependencies struct {
	Service       *application.RideService
	Verifier      *security.TokenManager
	RouteSecurity *middleware.RouteSecurity
}

func NewHandler(dependencies Dependencies) *Handler {
	return &Handler{
		service:  dependencies.Service,
		verifier: dependencies.Verifier,
	}
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
	var input CreateRideRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.FareAmount < 0 {
		response.Error(w, 400, "invalid fare")
		return
	}
	ride, err := handler.service.CreateRideWithDetails(r.Context(), domainRide(passengerID, input))
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, 201, rideResponseFromDomain(ride))
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
	response.JSON(w, 200, rideResponseFromDomain(item))
}

func (handler *Handler) MarkArrived(w http.ResponseWriter, r *http.Request) {
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
	var input ArrivalRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil ||
		input.Latitude == nil || input.Longitude == nil {
		response.Error(w, http.StatusBadRequest, "driver location is required")
		return
	}
	// Coordinates remain accepted for older clients, but lifecycle validation
	// deliberately reads server-owned telemetry instead of trusting this body.
	ride, err := handler.service.MarkArrived(
		r.Context(),
		rideID,
		driverID,
		*input.Latitude,
		*input.Longitude,
	)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
}

func (handler *Handler) StartTrip(w http.ResponseWriter, r *http.Request) {
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
	var input TripLocationRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil ||
		input.Latitude == nil || input.Longitude == nil {
		response.Error(w, http.StatusBadRequest, "driver location is required")
		return
	}
	ride, err := handler.service.StartTrip(
		r.Context(),
		rideID,
		driverID,
		*input.Latitude,
		*input.Longitude,
	)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
}

func (handler *Handler) CompleteTrip(w http.ResponseWriter, r *http.Request) {
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
	var input TripLocationRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil ||
		input.Latitude == nil || input.Longitude == nil {
		response.Error(w, http.StatusBadRequest, "driver location is required")
		return
	}
	ride, err := handler.service.CompleteTrip(
		r.Context(),
		rideID,
		driverID,
		*input.Latitude,
		*input.Longitude,
	)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
}

func (handler *Handler) MarkPassengerNoShow(w http.ResponseWriter, r *http.Request) {
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
	ride, err := handler.service.MarkPassengerNoShow(r.Context(), rideID, driverID)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
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
	var input StatusRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.Status == "" {
		response.Error(w, 400, "invalid ride status")
		return
	}
	item, err := handler.service.UpdateStatus(
		r.Context(),
		rideID,
		actorID,
		input.Status,
	)
	if err != nil {
		response.Error(w, 409, safeRideError(err))
		return
	}
	response.JSON(w, 200, rideResponseFromDomain(item))
}

func (handler *Handler) CancelRide(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid ride id")
		return
	}
	var input CancellationRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || strings.TrimSpace(input.Reason) == "" {
		response.Error(w, http.StatusBadRequest, "a cancellation reason is required")
		return
	}
	ride, err := handler.service.CancelRide(r.Context(), domain.CancellationRequest{
		RideID:  rideID,
		ActorID: actorID,
		Reason:  domain.CancellationReason(input.Reason),
		Details: input.Details,
	})
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
}

func (handler *Handler) EmergencyStop(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid ride id")
		return
	}
	var input EmergencyStopRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || strings.TrimSpace(input.Reason) == "" {
		response.Error(w, http.StatusBadRequest, "an emergency reason is required")
		return
	}
	ride, err := handler.service.EmergencyStop(r.Context(), domain.EmergencyStopRequest{
		RideID:  rideID,
		ActorID: actorID,
		Reason:  domain.EmergencyStopReason(input.Reason),
		Details: input.Details,
	})
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
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
	var input CashSettlementRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, http.StatusBadRequest, "invalid cash settlement")
		return
	}
	ride, err := handler.service.SettleCash(r.Context(), domain.CashSettlementRequest{
		RideID:         rideID,
		DriverID:       driverID,
		ReceivedAmount: input.CashReceivedAmount,
		ChangeAmount:   input.CashChangeAmount,
		Outcome:        domain.CashOutcome(strings.ToLower(strings.TrimSpace(input.CashOutcome))),
	})
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
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
	isPassenger := ride.PassengerID == actorID
	isDriver := ride.DriverID != nil && *ride.DriverID == actorID
	if !isPassenger && !isDriver {
		response.Error(w, 403, "forbidden")
		return
	}
	response.JSON(w, 200, rideResponseFromDomain(ride))
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
	response.JSON(w, http.StatusOK, NewCounterpartyResponse(result))
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
	response.JSON(
		w,
		200,
		response.NewOffsetPage(
			rideResponsesFromDomain(items),
			page.Limit,
			page.Offset,
		),
	)
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
	response.JSON(w, http.StatusOK, NewPassengerActivitySummaryResponse(summary))
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
	response.JSON(w, 200, NewDriverStatsResponse(stats))
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
	response.JSON(w, http.StatusOK, NewDriverEarningsResponse(summary))
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
	response.JSON(
		w,
		200,
		response.NewOffsetPage(
			rideResponsesFromDomain(items),
			page.Limit,
			page.Offset,
		),
	)
}

func (handler *Handler) CreateSafetyReport(w http.ResponseWriter, r *http.Request) {
	principal, ok := middleware.PrincipalFromRequest(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid ride id")
		return
	}
	var input SafetyReportRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, http.StatusBadRequest, "invalid safety report")
		return
	}
	item, err := handler.service.CreateSafetyReport(r.Context(), domain.SafetyReport{
		RideID:       rideID,
		ReporterID:   principal.UserID,
		ReporterRole: principal.Role,
		Category:     domain.SafetyReportCategory(input.Category),
		Description:  input.Description,
	})
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusCreated, NewSafetyReportResponse(item))
}

func (handler *Handler) Estimate(w http.ResponseWriter, r *http.Request) {
	var input FareEstimateRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, 400, "invalid fare input")
		return
	}
	metrics, total, err := handler.service.Fare(
		r.Context(),
		input.OriginLatitude,
		input.OriginLongitude,
		input.DestinationLatitude,
		input.DestinationLongitude,
		input.DistanceKm,
		input.DurationMinutes,
	)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	config := handler.service.PricingConfig()
	base := float64(config.BaseFareAmount) / 100
	distanceCharge := metrics.DistanceKm * float64(config.PerKilometerAmount) / 100
	timeCharge := metrics.DurationMinutes * float64(config.PerMinuteAmount) / 100
	response.JSON(w, 200, map[string]any{
		"base_fare":       base,
		"distance_charge": distanceCharge,
		"time_charge":     timeCharge,
		"surge_charge":    float64(0),
		"fare_amount":     total,
		"total_fare":      float64(total) / 100,
	})
}
func (handler *Handler) FareConfigs(w http.ResponseWriter, _ *http.Request) {
	response.JSON(w, 200, handler.service.PricingConfig().FareConfigsJSON())
}
func (handler *Handler) RatingConfig(w http.ResponseWriter, _ *http.Request) {
	response.JSON(w, 200, handler.service.PricingConfig().RatingConfigJSON())
}
func (handler *Handler) CalculateFinal(w http.ResponseWriter, r *http.Request) {
	var input FinalFareRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, 400, "invalid final fare input")
		return
	}
	invalidDistance := input.DistanceKm < 0
	invalidDuration := input.DurationMinutes < 0
	invalidCommission := input.CommissionBPS < 0 || input.CommissionBPS > 10000
	if invalidDistance || invalidDuration || invalidCommission {
		response.Error(w, 400, "invalid final fare input")
		return
	}
	metrics, fare, err := handler.service.Fare(
		r.Context(),
		input.OriginLatitude,
		input.OriginLongitude,
		input.DestinationLatitude,
		input.DestinationLongitude,
		input.DistanceKm,
		input.DurationMinutes,
	)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	commissionBPS := handler.service.PricingConfig().PlatformCommissionBPS
	commission := fare * commissionBPS / 10000
	response.JSON(w, 200, map[string]any{
		"fare_amount":          fare,
		"distance_km":          metrics.DistanceKm,
		"duration_minutes":     metrics.DurationMinutes,
		"commission_amount":    commission,
		"driver_payout_amount": fare - commission,
	})
}

func domainRide(passengerID int, input CreateRideRequest) domain.Ride {
	rideType := input.RideType
	if rideType == "" {
		rideType = "solo"
	}
	return domain.Ride{
		PassengerID:      passengerID,
		FareAmount:       input.FareAmount,
		Status:           "requested",
		RideType:         rideType,
		PickupLatitude:   input.PickupLatitude,
		PickupLongitude:  input.PickupLongitude,
		PickupName:       input.PickupName,
		DropoffLatitude:  input.DropoffLatitude,
		DropoffLongitude: input.DropoffLongitude,
		DropoffName:      input.DropoffName,
		DistanceKm:       input.DistanceKm,
		DurationMinutes:  input.DurationMinutes,
	}
}

func rideErrorStatus(err error) int {
	switch {
	case errors.Is(err, domain.ErrInvalidTrip):
		return 400
	case errors.Is(err, domain.ErrInvalidSettlement):
		return http.StatusBadRequest
	case errors.Is(err, domain.ErrInvalidCancellation):
		return http.StatusBadRequest
	case errors.Is(err, domain.ErrInvalidEmergencyStop):
		return http.StatusBadRequest
	case errors.Is(err, domain.ErrArrivalLocation),
		errors.Is(err, domain.ErrCompletionLocation):
		return http.StatusUnprocessableEntity
	case errors.Is(err, domain.ErrDriverLocationUnavailable),
		errors.Is(err, domain.ErrDriverLocationStale):
		return http.StatusServiceUnavailable
	case errors.Is(err, domain.ErrSafetyReportInvalid):
		return http.StatusBadRequest
	case errors.Is(err, domain.ErrSafetyReportNotAllowed):
		return http.StatusForbidden
	case errors.Is(err, domain.ErrSafetyReportAlreadySent):
		return http.StatusConflict
	case errors.Is(err, domain.ErrRouteUnavailable):
		return 503
	case errors.Is(err, domain.ErrUnauthorizedRide):
		return 403
	case errors.Is(err, domain.ErrActiveBooking),
		errors.Is(err, domain.ErrDriverHasActiveRide),
		errors.Is(err, domain.ErrDriverSettlementOverdue),
		errors.Is(err, domain.ErrDriverUnavailable),
		errors.Is(err, domain.ErrInvalidStatusTransition),
		errors.Is(err, domain.ErrCancellationCommand),
		errors.Is(err, domain.ErrArrivalCommand),
		errors.Is(err, domain.ErrTripStartCommand),
		errors.Is(err, domain.ErrTripCompletionCommand),
		errors.Is(err, domain.ErrPassengerNoShowNotReady),
		errors.Is(err, domain.ErrNoShowCommand),
		errors.Is(err, domain.ErrEmergencyStopNotAllowed):
		return 409
	default:
		return 500
	}
}

func safeRideError(err error) string {
	switch {
	case errors.Is(err, domain.ErrInvalidTrip):
		return "The route details are invalid."
	case errors.Is(err, domain.ErrInvalidSettlement):
		return "The cash amount or payment outcome is invalid."
	case errors.Is(err, domain.ErrRouteUnavailable):
		return "The route service is temporarily unavailable."
	case errors.Is(err, domain.ErrActiveBooking):
		return "You already have an active ride."
	case errors.Is(err, domain.ErrDriverHasActiveRide):
		return "This driver is already handling another ride."
	case errors.Is(err, domain.ErrDriverSettlementOverdue):
		return "Settle the overdue cash ride before accepting another request."
	case errors.Is(err, domain.ErrUnauthorizedRide):
		return "You do not have access to this ride."
	case errors.Is(err, domain.ErrDriverUnavailable):
		return "This driver is no longer available."
	case errors.Is(err, domain.ErrInvalidStatusTransition):
		return "That ride status cannot be changed right now."
	case errors.Is(err, domain.ErrCancellationCommand):
		return "Use the cancellation action with a reason."
	case errors.Is(err, domain.ErrInvalidCancellation):
		return "Choose a valid cancellation reason for this ride."
	case errors.Is(err, domain.ErrInvalidEmergencyStop):
		return "Choose a valid emergency reason for this ride."
	case errors.Is(err, domain.ErrEmergencyStopNotAllowed):
		return "An emergency stop is not available for this ride right now."
	case errors.Is(err, domain.ErrArrivalCommand):
		return "Confirm arrival from the pickup action with location enabled."
	case errors.Is(err, domain.ErrArrivalLocation):
		return "The driver must be in the passenger's pickup area before confirming arrival."
	case errors.Is(err, domain.ErrDriverLocationUnavailable):
		return "Your live location is unavailable. Keep location sharing on and try again."
	case errors.Is(err, domain.ErrDriverLocationStale):
		return "Your live location is out of date. Keep location sharing on and try again."
	case errors.Is(err, domain.ErrTripStartCommand):
		return "Start the trip from the passenger pickup action."
	case errors.Is(err, domain.ErrTripCompletionCommand):
		return "Complete the trip from the destination action."
	case errors.Is(err, domain.ErrCompletionLocation):
		return "The driver must be in the destination area before completing the trip."
	case errors.Is(err, domain.ErrPassengerNoShowNotReady):
		return "Keep waiting until the pickup timer finishes before marking a no-show."
	case errors.Is(err, domain.ErrNoShowCommand):
		return "Use the passenger no-show action after the waiting period."
	case errors.Is(err, domain.ErrSafetyReportInvalid):
		return "Choose a valid report category and describe what happened."
	case errors.Is(err, domain.ErrSafetyReportNotAllowed):
		return "Only ride participants can report this ride."
	case errors.Is(err, domain.ErrSafetyReportAlreadySent):
		return "You already submitted this report for the ride."
	default:
		return "The ride request could not be completed."
	}
}
