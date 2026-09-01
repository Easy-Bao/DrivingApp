package http

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http/dto"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service *application.LocationTrackingService
	auth    *security.TokenManager
}

func NewHandler(
	service *application.LocationTrackingService,
	auth *security.TokenManager,
) *Handler {
	return &Handler{service: service, auth: auth}
}

func (handler *Handler) UpdateDriverLocation(writer http.ResponseWriter, request *http.Request) {
	var input dto.LocationUpdate
	if sharedrequest.DecodeJSON(writer, request, &input, 8<<10) != nil {
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
		Heading: input.Heading, Speed: input.Speed,
	}

	if err := handler.service.Ingest(request.Context(), point); err != nil {
		if errors.Is(err, domain.ErrInvalidLocation) {
			response.Error(writer, http.StatusBadRequest, "invalid location")
			return
		}
		response.Error(writer, http.StatusInternalServerError, "could not save location")
		return
	}
	response.JSON(writer, http.StatusAccepted, map[string]any{"success": true, "location": point})
}

func (handler *Handler) GetDriverLocation(writer http.ResponseWriter, request *http.Request) {
	driverID := chi.URLParam(request, "driverID")
	identity, ok := handler.identity(request)
	if !ok || identity.Role != "driver" || identity.Subject != driverID {
		response.Error(writer, http.StatusForbidden, "forbidden")
		return
	}
	point, err := handler.service.Get(request.Context(), driverID)
	if err != nil {
		response.Error(writer, http.StatusNotFound, "location not found")
		return
	}
	response.JSON(writer, http.StatusOK, point)
}

func (handler *Handler) GetRideDriverLocation(writer http.ResponseWriter, request *http.Request) {
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
	response.JSON(writer, http.StatusOK, point)
}

func (handler *Handler) DeleteDriverLocation(writer http.ResponseWriter, request *http.Request) {
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

func (handler *Handler) UpdatePassengerLocation(writer http.ResponseWriter, request *http.Request) {
	if handler.auth == nil {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	identity, ok := handler.identity(request)
	if !ok || identity.Role != "passenger" {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input dto.PassengerLocationUpdate
	if sharedrequest.DecodeJSON(writer, request, &input, 8<<10) != nil {
		response.Error(writer, http.StatusBadRequest, "invalid location")
		return
	}
	point := domain.DriverPoint{Latitude: input.Latitude, Longitude: input.Longitude}
	if err := handler.service.UpdatePassenger(request.Context(), chi.URLParam(request, "rideID"), identity.Subject, point); err != nil {
		writeRideLocationError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, map[string]bool{"success": true})
}

func (handler *Handler) GetPassengerLocation(writer http.ResponseWriter, request *http.Request) {
	if handler.auth == nil {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	identity, ok := handler.identity(request)
	if !ok || identity.Role != "driver" {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	point, err := handler.service.GetPassengerForDriver(request.Context(), chi.URLParam(request, "rideID"), identity.Subject)
	if err != nil {
		writeRideLocationError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, point)
}

func (handler *Handler) NearbyDrivers(writer http.ResponseWriter, request *http.Request) {
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
	if latErr != nil || lonErr != nil || radiusErr != nil || radius <= 0 || radius > 50 || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 {
		response.Error(writer, http.StatusBadRequest, "invalid nearby query")
		return
	}
	points, err := handler.service.Nearby(request.Context(), latitude, longitude, radius)
	if err != nil {
		response.Error(writer, http.StatusServiceUnavailable, "driver availability unavailable")
		return
	}
	response.JSON(writer, http.StatusOK, map[string]any{"drivers": points})
}

func (handler *Handler) identity(request *http.Request) (security.Identity, bool) {
	return middleware.IdentityFromRequest(request, handler.auth)
}

func writeRideLocationError(writer http.ResponseWriter, err error) {
	if errors.Is(err, domain.ErrInvalidLocation) {
		response.Error(writer, http.StatusBadRequest, "invalid location")
		return
	}
	if errors.Is(err, domain.ErrRideAccessDenied) || errors.Is(err, domain.ErrRideAssignmentUnavailable) {
		response.Error(writer, http.StatusForbidden, "forbidden")
		return
	}
	response.Error(writer, http.StatusInternalServerError, "could not access location")
}
