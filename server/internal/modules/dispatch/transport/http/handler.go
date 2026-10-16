package http

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	dispatchapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	ridedto "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/transport/http"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service      *dispatchapp.Service
	availability *dispatchapp.AvailabilityService
	verifier     *security.TokenManager
}

type Dependencies struct {
	Service       *dispatchapp.Service
	Availability  *dispatchapp.AvailabilityService
	Verifier      *security.TokenManager
	RouteSecurity *middleware.RouteSecurity
}

func NewHandler(dependencies Dependencies) *Handler {
	return &Handler{
		service:      dependencies.Service,
		availability: dependencies.Availability,
		verifier:     dependencies.Verifier,
	}
}

func (handler *Handler) identity(r *http.Request) (int, bool) {
	return middleware.AuthenticatedUserID(r, handler.verifier)
}

func (handler *Handler) CreateSession(w http.ResponseWriter, r *http.Request) {
	passengerID, ok := handler.identity(r)
	if !ok {
		response.Error(w, 401, "unauthorized")
		return
	}
	var input BidSessionRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, 400, "invalid bid session")
		return
	}
	session, err := handler.service.CreateSession(r.Context(), dispatchdomain.BidSession{
		PassengerID:      passengerID,
		RideType:         input.RideType,
		PickupLatitude:   input.PickupLatitude,
		PickupLongitude:  input.PickupLongitude,
		PickupName:       input.PickupName,
		DropoffLatitude:  input.DropoffLatitude,
		DropoffLongitude: input.DropoffLongitude,
		DropoffName:      input.DropoffName,
		PassengerNote:    strings.TrimSpace(input.PassengerNote),
		DistanceKm:       input.DistanceKm,
		DurationMinutes:  input.DurationMinutes,
		TargetDriverID:   input.TargetDriverID,
		CustomFareAmount: input.CustomFareAmount,
	})
	if err != nil {
		response.Error(w, dispatchErrorStatus(err), safeDispatchError(err))
		return
	}
	response.JSON(w, 201, NewBidSessionResponse(session))
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
	response.JSON(w, 200, NewBidSessionResponses(sessions))
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
	response.JSON(w, 200, NewBidSessionResponse(item))
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
	response.JSON(w, 200, NewBidOfferResponses(items))
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
	var input BidOfferRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil {
		response.Error(w, 400, "invalid bid offer")
		return
	}
	fare := input.ProposedFareAmount
	if fare == 0 && input.OfferPrice > 0 {
		fare = int64(input.OfferPrice * 100)
	}
	offer, err := handler.service.PlaceOffer(r.Context(), dispatchdomain.BidOffer{
		SessionID:          sessionID,
		DriverID:           driverID,
		DriverName:         input.DriverName,
		PlateNumber:        input.PlateNumber,
		VehicleType:        input.VehicleType,
		ProposedFareAmount: fare,
	})
	if err != nil {
		response.Error(w, 409, safeDispatchError(err))
		return
	}
	response.JSON(w, 201, NewBidOfferResponse(offer))
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
	session, offer, ride, err := handler.service.AcceptOffer(
		r.Context(),
		sessionID,
		offerID,
		passengerID,
	)
	if err != nil {
		response.Error(w, 409, "offer cannot be accepted")
		return
	}
	response.JSON(w, http.StatusOK, AcceptedOfferResponse{
		Session: NewBidSessionResponse(session),
		Offer:   NewBidOfferResponse(offer),
		Ride:    ridedto.NewRideResponse(ride),
		RideID:  ride.ID,
	})
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
	response.JSON(w, 200, NewBidSessionResponse(item))
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
	response.JSON(w, 200, NewBidOfferResponse(item))
}

func canViewSession(actorID int, session dispatchdomain.BidSession) bool {
	if session.PassengerID == actorID {
		return true
	}
	return session.TargetDriverID != nil && *session.TargetDriverID == actorID
}

func dispatchErrorStatus(err error) int {
	switch {
	case errors.Is(err, ridedomain.ErrInvalidTrip), errors.Is(err, dispatchdomain.ErrInvalidFareOffer):
		return http.StatusBadRequest
	case errors.Is(err, ridedomain.ErrActiveBooking),
		errors.Is(err, ridedomain.ErrDriverHasActiveRide),
		errors.Is(err, ridedomain.ErrDriverSettlementOverdue),
		errors.Is(err, dispatchdomain.ErrDriverUnavailable),
		errors.Is(err, dispatchdomain.ErrDuplicateBid):
		return http.StatusConflict
	case errors.Is(err, dispatchdomain.ErrUnauthorizedSession):
		return http.StatusForbidden
	case errors.Is(err, ridedomain.ErrRouteUnavailable):
		return http.StatusServiceUnavailable
	default:
		return http.StatusInternalServerError
	}
}

func safeDispatchError(err error) string {
	switch {
	case errors.Is(err, ridedomain.ErrInvalidTrip):
		return "The route details are invalid."
	case errors.Is(err, dispatchdomain.ErrInvalidFareOffer):
		return "The custom offer cannot be lower than the calculated minimum fare."
	case errors.Is(err, ridedomain.ErrRouteUnavailable):
		return "The route service is temporarily unavailable."
	case errors.Is(err, ridedomain.ErrActiveBooking):
		return "You already have an active ride."
	case errors.Is(err, ridedomain.ErrDriverHasActiveRide):
		return "This driver is already handling another ride."
	case errors.Is(err, ridedomain.ErrDriverSettlementOverdue):
		return "Settle the overdue cash ride before accepting another request."
	case errors.Is(err, dispatchdomain.ErrUnauthorizedSession):
		return "You do not have access to this ride."
	case errors.Is(err, dispatchdomain.ErrDriverUnavailable):
		return "This driver is no longer available."
	case errors.Is(err, dispatchdomain.ErrDuplicateBid):
		return "You already sent an offer for this ride."
	default:
		return "The ride request could not be completed."
	}
}
