package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"net/http"
	"strings"
)

func (handler *Handler) AcceptRide(w http.ResponseWriter, r *http.Request) {
	driverID, rideID, ok := handler.driverRideCommand(w, r)
	if !ok {
		return
	}
	item, err := handler.service.AcceptRide(r.Context(), rideID, driverID)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(item))
}

func (handler *Handler) MarkArrived(w http.ResponseWriter, r *http.Request) {
	driverID, rideID, latitude, longitude, ok := handler.driverRideLocationCommand(w, r)
	if !ok {
		return
	}
	// Coordinates remain accepted for older clients, but lifecycle validation
	// deliberately reads server-owned telemetry instead of trusting this body.
	ride, err := handler.service.MarkArrived(r.Context(), rideID, driverID, latitude, longitude)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
}

func (handler *Handler) StartTrip(w http.ResponseWriter, r *http.Request) {
	driverID, rideID, latitude, longitude, ok := handler.driverRideLocationCommand(w, r)
	if !ok {
		return
	}
	ride, err := handler.service.StartTrip(r.Context(), rideID, driverID, latitude, longitude)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
}

func (handler *Handler) CompleteTrip(w http.ResponseWriter, r *http.Request) {
	driverID, rideID, latitude, longitude, ok := handler.driverRideLocationCommand(w, r)
	if !ok {
		return
	}
	ride, err := handler.service.CompleteTrip(r.Context(), rideID, driverID, latitude, longitude)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(ride))
}

func (handler *Handler) MarkPassengerNoShow(w http.ResponseWriter, r *http.Request) {
	driverID, rideID, ok := handler.driverRideCommand(w, r)
	if !ok {
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
	actorID, rideID, ok := handler.driverRideCommand(w, r)
	if !ok {
		return
	}
	var input StatusRequest
	if sharedrequest.DecodeJSONV2(w, r, &input, 16<<10) != nil || input.Status == "" {
		response.Error(w, http.StatusBadRequest, "invalid ride status")
		return
	}
	item, err := handler.service.UpdateStatus(
		r.Context(),
		rideID,
		actorID,
		input.Status,
	)
	if err != nil {
		response.Error(w, rideErrorStatus(err), safeRideError(err))
		return
	}
	response.JSON(w, http.StatusOK, rideResponseFromDomain(item))
}

func (handler *Handler) CancelRide(w http.ResponseWriter, r *http.Request) {
	actorID, rideID, ok := handler.driverRideCommand(w, r)
	if !ok {
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
	actorID, rideID, ok := handler.driverRideCommand(w, r)
	if !ok {
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
	driverID, rideID, ok := handler.driverRideCommand(w, r)
	if !ok {
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
