package http

import (
	"errors"
	"net/http"
	"strconv"

	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

type Handler struct {
	service  *application.Service
	verifier *security.TokenManager
}

type Dependencies struct {
	Service       *application.Service
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
func (handler *Handler) principal(r *http.Request) (middleware.Principal, bool) {
	if principal, ok := middleware.PrincipalFromRequest(r); ok {
		return principal, true
	}
	identity, ok := middleware.IdentityFromRequest(r, handler.verifier)
	if !ok {
		return middleware.Principal{}, false
	}
	userID, err := strconv.Atoi(identity.Subject)
	if err != nil || userID <= 0 {
		return middleware.Principal{}, false
	}
	return middleware.Principal{UserID: userID, Role: identity.Role}, true
}
func (handler *Handler) CreateRide(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input CreateRideRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.FareAmount < 0 {
		response.Error(w, http.StatusBadRequest, "invalid fare")
		return
	}
	ride, err := handler.service.CreateRideWithDetails(r.Context(), domainRide(passengerID, input))
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusCreated, rideResponseFromDomain(ride))
}

func (handler *Handler) GetRide(w http.ResponseWriter, r *http.Request) {
	actorID, id, ok := handler.driverRideCommand(w, r)
	if !ok {
		return
	}
	ride, err := handler.service.Get(r.Context(), id)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	isPassenger := ride.PassengerID == actorID
	isDriver := ride.DriverID != nil && *ride.DriverID == actorID
	if !isPassenger && !isDriver {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
}

func (handler *Handler) Counterparty(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	rideID, ok := sharedrequest.PositiveIntParam(w, r, "id", "invalid ride id")
	if !ok {
		return
	}
	result, err := handler.service.Counterparty(r.Context(), rideID, actorID)
	if err != nil {
		switch {
		case errors.Is(err, domain.ErrUnauthorizedRide):
			response.Error(w, http.StatusForbidden, "forbidden")
		case errors.Is(err, domain.ErrCounterpartyUnavailable):
			response.Error(w, http.StatusConflict, "ride counterparty is unavailable")
		case errors.Is(err, domain.ErrRideNotFound):
			response.Error(w, http.StatusNotFound, "ride counterparty not found")
		default:
			response.Error(w, http.StatusServiceUnavailable, "ride counterparty is unavailable")
		}
		return
	}
	response.JSON(w, http.StatusOK, NewCounterpartyResponse(result))
}

func (handler *Handler) CreateSafetyReport(w http.ResponseWriter, r *http.Request) {
	principal, ok := handler.principal(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	rideID, ok := sharedrequest.PositiveIntParam(w, r, "id", "invalid ride id")
	if !ok {
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
		response.Error(w, http.StatusBadRequest, "invalid fare input")
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
	response.JSON(w, http.StatusOK, map[string]any{
		"base_fare":       base,
		"distance_charge": distanceCharge,
		"time_charge":     timeCharge,
		"surge_charge":    float64(0),
		"fare_amount":     total,
		"total_fare":      float64(total) / 100,
	})
}
func (handler *Handler) FareConfigs(w http.ResponseWriter, _ *http.Request) {
	response.JSON(w, http.StatusOK, handler.service.PricingConfig().FareConfigsJSON())
}
func (handler *Handler) RatingConfig(w http.ResponseWriter, _ *http.Request) {
	response.JSON(w, http.StatusOK, handler.service.PricingConfig().RatingConfigJSON())
}
func (handler *Handler) CalculateFinal(w http.ResponseWriter, r *http.Request) {
	if handler.verifier != nil {
		principal, ok := handler.principal(r)
		if !ok {
			response.Error(w, http.StatusUnauthorized, "unauthorized")
			return
		}
		if principal.Role != security.RoleDriver && principal.Role != "admin" {
			response.Error(w, http.StatusForbidden, "forbidden")
			return
		}
	}
	var input FinalFareRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, http.StatusBadRequest, "invalid final fare input")
		return
	}
	invalidDistance := input.DistanceKm < 0
	invalidDuration := input.DurationMinutes < 0
	if invalidDistance || invalidDuration {
		response.Error(w, http.StatusBadRequest, "invalid final fare input")
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
	snapshot, err := domain.NewSettlementSnapshot(fare, handler.service.PricingConfig().PlatformCommissionBPS)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, map[string]any{
		"fare_amount":          snapshot.FareAmount,
		"distance_km":          metrics.DistanceKm,
		"duration_minutes":     metrics.DurationMinutes,
		"commission_amount":    snapshot.CommissionAmount,
		"driver_payout_amount": snapshot.DriverPayoutAmount,
	})
}

func (handler *Handler) driverRideCommand(w http.ResponseWriter, r *http.Request) (int, int, bool) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return 0, 0, false
	}
	rideID, ok := sharedrequest.PositiveIntParam(w, r, "id", "invalid ride id")
	if !ok {
		return 0, 0, false
	}
	return actorID, rideID, true
}

func (handler *Handler) driverRideLocationCommand(w http.ResponseWriter, r *http.Request) (int, int, float64, float64, bool) {
	driverID, rideID, ok := handler.driverRideCommand(w, r)
	if !ok {
		return 0, 0, 0, 0, false
	}
	var input TripLocationRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil ||
		input.Latitude == nil || input.Longitude == nil {
		response.Error(w, http.StatusBadRequest, "driver location is required")
		return 0, 0, 0, 0, false
	}
	return driverID, rideID, *input.Latitude, *input.Longitude, true
}

func domainRide(passengerID int, input CreateRideRequest) domain.Ride {

	return domain.Ride{
		PassengerID: passengerID,
		FareAmount:  input.FareAmount,
		Status:      "requested",

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
	case errors.Is(err, domain.ErrRideNotFound):
		return http.StatusNotFound
	case errors.Is(err, domain.ErrInvalidTrip),
		errors.Is(err, domain.ErrInvalidSettlement),
		errors.Is(err, domain.ErrInvalidCancellation),
		errors.Is(err, domain.ErrInvalidEmergencyStop),
		errors.Is(err, domain.ErrSafetyReportInvalid):
		return http.StatusBadRequest
	case errors.Is(err, domain.ErrArrivalLocation):
		return http.StatusUnprocessableEntity
	case errors.Is(err, domain.ErrDriverLocationUnavailable),
		errors.Is(err, domain.ErrDriverLocationStale),
		errors.Is(err, domain.ErrRouteUnavailable):
		return http.StatusServiceUnavailable
	case errors.Is(err, domain.ErrSafetyReportNotAllowed),
		errors.Is(err, domain.ErrUnauthorizedRide):
		return http.StatusForbidden
	case errors.Is(err, domain.ErrSafetyReportAlreadySent),
		errors.Is(err, domain.ErrActiveBooking),
		errors.Is(err, domain.ErrDriverCapacityReached),
		errors.Is(err, domain.ErrDriverUnavailable),
		errors.Is(err, domain.ErrInvalidStatusTransition),
		errors.Is(err, domain.ErrCancellationCommand),
		errors.Is(err, domain.ErrArrivalCommand),
		errors.Is(err, domain.ErrTripStartCommand),
		errors.Is(err, domain.ErrTripCompletionCommand),
		errors.Is(err, domain.ErrPassengerNoShowNotReady),
		errors.Is(err, domain.ErrNoShowCommand),
		errors.Is(err, domain.ErrEmergencyStopNotAllowed):
		return http.StatusConflict
	default:
		return http.StatusInternalServerError
	}
}

func safeRideError(err error) string {
	switch {
	case errors.Is(err, domain.ErrRideNotFound):
		return "Ride not found."
	case errors.Is(err, domain.ErrInvalidTrip):
		return "The route details are invalid."
	case errors.Is(err, domain.ErrInvalidSettlement):
		return "The cash amount or payment outcome is invalid."
	case errors.Is(err, domain.ErrRouteUnavailable):
		return "The route service is temporarily unavailable."
	case errors.Is(err, domain.ErrActiveBooking):
		return "You already have an active ride."
	case errors.Is(err, domain.ErrDriverCapacityReached):
		return "This driver already has five active bookings."
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
		return "You must be at the passenger's pickup point to confirm arrival."
	case errors.Is(err, domain.ErrDriverLocationUnavailable):
		return "Your live location is unavailable. Keep location sharing on and try again."
	case errors.Is(err, domain.ErrDriverLocationStale):
		return "Your live location is out of date. Keep location sharing on and try again."
	case errors.Is(err, domain.ErrTripStartCommand):
		return "Start the trip from the passenger pickup action."
	case errors.Is(err, domain.ErrTripCompletionCommand):
		return "Complete the trip from the destination action."
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
