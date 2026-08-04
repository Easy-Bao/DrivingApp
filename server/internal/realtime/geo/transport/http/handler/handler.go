package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service *usecase.Service
	auth    *security.TokenManager
}

func NewHandler(service *usecase.Service, auth ...*security.TokenManager) *Handler {
	var tokenManager *security.TokenManager
	if len(auth) > 0 {
		tokenManager = auth[0]
	}
	return &Handler{service: service, auth: tokenManager}
}

func (router *Handler) RegisterRoutes(r chi.Router) {
	r.Post("/api/v1/telemetry/location", router.update)
	r.Get("/api/v1/telemetry/location/nearby", router.nearby)
	r.Get("/api/v1/telemetry/location/{driverID}", router.get)
	r.Post("/api/v1/telemetry/passenger/{rideID}", router.updatePassenger)
	r.Get("/api/v1/telemetry/passenger/{rideID}", router.getPassenger)
	r.Post("/telemetry/location", router.update)
	r.Get("/telemetry/location/{driverID}", router.get)
	r.Post("/telemetry/passenger/{rideID}", router.updatePassenger)
	r.Get("/telemetry/passenger/{rideID}", router.getPassenger)
}

func (router *Handler) update(writer http.ResponseWriter, request *http.Request) {
	var input dto.LocationUpdate
	if json.NewDecoder(request.Body).Decode(&input) != nil {
		writeError(writer, http.StatusBadRequest, "invalid location")
		return
	}
	if router.auth != nil {
		identity, ok := router.identity(request)
		if !ok {
			writeError(writer, http.StatusUnauthorized, "unauthorized")
			return
		}
		input.DriverID = identity
	} else if input.DriverID == "" {
		input.DriverID = input.LegacyID
	}
	if input.Latitude == 0 {
		input.Latitude = input.Lat
	}
	if input.Longitude == 0 {
		input.Longitude = input.Lng
	}
	point := domain.DriverPoint{DriverID: input.DriverID, Latitude: input.Latitude, Longitude: input.Longitude}
	if point.DriverID == "" {
		writeError(writer, http.StatusBadRequest, "driver id is required")
		return
	}
	if err := router.service.Ingest(request.Context(), point); err != nil {
		writeError(writer, http.StatusInternalServerError, "could not save location")
		return
	}
	writeJSON(writer, http.StatusAccepted, map[string]any{"success": true, "location": point})
}

func (router *Handler) get(writer http.ResponseWriter, request *http.Request) {
	point, err := router.service.Get(request.Context(), chi.URLParam(request, "driverID"))
	if err != nil {
		writeError(writer, http.StatusNotFound, "location not found")
		return
	}
	writeJSON(writer, http.StatusOK, point)
}

func (router *Handler) updatePassenger(writer http.ResponseWriter, request *http.Request) {
	if router.auth != nil {
		if _, ok := router.identity(request); !ok {
			writeError(writer, http.StatusUnauthorized, "unauthorized")
			return
		}
	}
	var input dto.PassengerLocationUpdate
	if json.NewDecoder(request.Body).Decode(&input) != nil {
		writeError(writer, http.StatusBadRequest, "invalid location")
		return
	}
	if input.Latitude == 0 {
		input.Latitude = input.Lat
	}
	if input.Longitude == 0 {
		input.Longitude = input.Lng
	}
	point := domain.DriverPoint{Latitude: input.Latitude, Longitude: input.Longitude}
	if err := router.service.UpdatePassenger(request.Context(), chi.URLParam(request, "rideID"), point); err != nil {
		writeError(writer, http.StatusInternalServerError, "could not save location")
		return
	}
	writeJSON(writer, http.StatusOK, map[string]bool{"success": true})
}

func (router *Handler) getPassenger(writer http.ResponseWriter, request *http.Request) {
	point, err := router.service.GetPassenger(request.Context(), chi.URLParam(request, "rideID"))
	if err != nil {
		writeError(writer, http.StatusNotFound, "location not found")
		return
	}
	writeJSON(writer, http.StatusOK, point)
}

func (router *Handler) nearby(writer http.ResponseWriter, request *http.Request) {
	if router.auth != nil {
		if _, ok := router.identity(request); !ok {
			writeError(writer, http.StatusUnauthorized, "unauthorized")
			return
		}
	}
	query := request.URL.Query()
	latitude, latErr := strconv.ParseFloat(query.Get("latitude"), 64)
	longitude, lonErr := strconv.ParseFloat(query.Get("longitude"), 64)
	radius, radiusErr := strconv.ParseFloat(query.Get("radius_km"), 64)
	if latErr != nil || lonErr != nil || radiusErr != nil || radius <= 0 || radius > 50 || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 {
		writeError(writer, http.StatusBadRequest, "invalid nearby query")
		return
	}
	points, err := router.service.Nearby(request.Context(), latitude, longitude, radius)
	if err != nil {
		writeError(writer, http.StatusInternalServerError, "could not load nearby drivers")
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"drivers": points})
}

func (router *Handler) identity(request *http.Request) (string, bool) {
	const prefix = "Bearer "
	header := request.Header.Get("Authorization")
	if len(header) <= len(prefix) || header[:len(prefix)] != prefix {
		return "", false
	}
	subject, err := router.auth.Verify(header[len(prefix):])
	return subject, err == nil && subject != ""
}

func writeJSON(writer http.ResponseWriter, status int, value any) {
	response.JSON(writer, status, value)
}
func writeError(writer http.ResponseWriter, status int, message string) {
	writeJSON(writer, status, map[string]string{"error": message})
}
