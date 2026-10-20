package http

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	locationapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type TrackingHandler struct {
	service *locationapp.TrackingService
	auth    *security.TokenManager
}

type TrackingDependencies struct {
	Service       *locationapp.TrackingService
	Auth          *security.TokenManager
	RouteSecurity *middleware.RouteSecurity
}

func NewTrackingHandler(dependencies TrackingDependencies) *TrackingHandler {
	return &TrackingHandler{service: dependencies.Service, auth: dependencies.Auth}
}

func (handler *TrackingHandler) UpdateDriverLocation(writer http.ResponseWriter, request *http.Request) {
	var input LocationUpdate
	if sharedrequest.DecodeJSONV2(writer, request, &input, 8<<10) != nil {
		response.Error(writer, http.StatusBadRequest, "invalid location")
		return
	}
	identity, ok := handler.identity(request)
	if !ok || identity.Role != "driver" {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	point := domain.DriverPoint{
		DriverID: identity.Subject, Latitude: input.Latitude, Longitude: input.Longitude,
		Heading: input.Heading, Speed: input.Speed, ObservedAt: input.ObservedAt,
	}
	if point.ObservedAt.IsZero() {
		point.ObservedAt = time.Now().UTC()
	}

	if err := handler.service.Ingest(request.Context(), point); err != nil {
		if errors.Is(err, domain.ErrInvalidLocation) {
			response.Error(writer, http.StatusBadRequest, "invalid location")
			return
		}
		if errors.Is(err, domain.ErrDriverOffline) {
			response.Error(writer, http.StatusConflict, "driver must be online to share location")
			return
		}
		if errors.Is(err, domain.ErrDriverPresenceUnavailable) {
			response.Error(writer, http.StatusServiceUnavailable, "driver availability unavailable")
			return
		}
		response.Error(writer, http.StatusInternalServerError, "could not save location")
		return
	}
	response.JSON(writer, http.StatusAccepted, map[string]any{
		"success":  true,
		"location": NewDriverLocationResponse(point),
	})
}

func (handler *TrackingHandler) GetDriverLocation(writer http.ResponseWriter, request *http.Request) {
	driverID := chi.URLParam(request, "driverID")
	identity, ok := handler.identity(request)
	invalidIdentity := !ok
	wrongRole := identity.Role != "driver"
	wrongDriver := identity.Subject != driverID
	if invalidIdentity || wrongRole || wrongDriver {
		response.Error(writer, http.StatusForbidden, "forbidden")
		return
	}
	point, err := handler.service.Get(request.Context(), driverID)
	if err != nil {
		if errors.Is(err, domain.ErrLocationNotFound) {
			response.Error(writer, http.StatusNotFound, "location not found")
			return
		}
		response.Error(writer, http.StatusInternalServerError, "could not access location")
		return
	}
	response.JSON(writer, http.StatusOK, NewDriverLocationResponse(point))
}

func (handler *TrackingHandler) GetRideDriverLocation(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok || identity.Role != "passenger" {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	point, err := handler.service.GetDriverForRide(
		request.Context(),
		chi.URLParam(request, "rideID"),
		identity.Subject,
	)
	if err != nil {
		writeRideLocationError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, NewDriverLocationResponse(point))
}

func (handler *TrackingHandler) DeleteDriverLocation(writer http.ResponseWriter, request *http.Request) {
	if handler.auth == nil {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	identity, ok := handler.identity(request)
	if !ok || identity.Role != "driver" {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	if err := handler.service.Remove(request.Context(), identity.Subject); err != nil {
		response.Error(writer, http.StatusInternalServerError, "could not remove location")
		return
	}
	writer.WriteHeader(http.StatusNoContent)
}

func (handler *TrackingHandler) UpdatePassengerLocation(writer http.ResponseWriter, request *http.Request) {
	if handler.auth == nil {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	identity, ok := handler.identity(request)
	if !ok || identity.Role != "passenger" {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input PassengerLocationUpdate
	if sharedrequest.DecodeJSONV2(writer, request, &input, 8<<10) != nil {
		response.Error(writer, http.StatusBadRequest, "invalid location")
		return
	}
	point := domain.DriverPoint{Latitude: input.Latitude, Longitude: input.Longitude}
	if err := handler.service.UpdatePassenger(
		request.Context(),
		chi.URLParam(request, "rideID"),
		identity.Subject,
		point,
	); err != nil {
		writeRideLocationError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, map[string]bool{"success": true})
}

func (handler *TrackingHandler) GetPassengerLocation(writer http.ResponseWriter, request *http.Request) {
	if handler.auth == nil {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	identity, ok := handler.identity(request)
	if !ok || identity.Role != "driver" {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	point, err := handler.service.GetPassengerForDriver(
		request.Context(),
		chi.URLParam(request, "rideID"),
		identity.Subject,
	)
	if err != nil {
		writeRideLocationError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, NewDriverLocationResponse(point))
}

func (handler *TrackingHandler) NearbyDrivers(writer http.ResponseWriter, request *http.Request) {
	if handler.auth != nil {
		if _, ok := handler.identity(request); !ok {
			response.Error(writer, http.StatusUnauthorized, "unauthorized")
			return
		}
	}
	query := request.URL.Query()
	latitude, latErr := strconv.ParseFloat(query.Get("latitude"), 64)
	longitude, lonErr := strconv.ParseFloat(query.Get("longitude"), 64)
	radius, radiusErr := strconv.ParseFloat(query.Get("radius_km"), 64)
	parseFailed := latErr != nil || lonErr != nil || radiusErr != nil
	invalidCoordinates := latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180
	invalidRadius := radius <= 0 || radius > 50
	if parseFailed || invalidCoordinates || invalidRadius {
		response.Error(writer, http.StatusBadRequest, "invalid nearby query")
		return
	}
	points, err := handler.service.Nearby(request.Context(), latitude, longitude, radius)
	if err != nil {
		response.Error(writer, http.StatusServiceUnavailable, "driver availability unavailable")
		return
	}
	response.JSON(writer, http.StatusOK, map[string]any{
		"drivers": NewDriverLocationResponses(points),
	})
}

func (handler *TrackingHandler) identity(request *http.Request) (security.Identity, bool) {
	return middleware.IdentityFromRequest(request, handler.auth)
}

func writeRideLocationError(writer http.ResponseWriter, err error) {
	if errors.Is(err, domain.ErrInvalidLocation) {
		response.Error(writer, http.StatusBadRequest, "invalid location")
		return
	}
	if errors.Is(err, domain.ErrLocationNotFound) {
		response.Error(writer, http.StatusNotFound, "location not found")
		return
	}
	if errors.Is(err, domain.ErrRideAccessDenied) || errors.Is(err, domain.ErrRideAssignmentUnavailable) {
		response.Error(writer, http.StatusForbidden, "forbidden")
		return
	}
	response.Error(writer, http.StatusInternalServerError, "could not access location")
}
