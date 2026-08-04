package http

import (
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"net/http"
	"strconv"
)

type Router struct{ service *usecase.Service }

func NewRouter(service *usecase.Service) *Router { return &Router{service: service} }

func (router *Router) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/telemetry/location", router.update)
	mux.HandleFunc("GET /api/v1/telemetry/location/nearby", router.nearby)
}

func (router *Router) update(writer http.ResponseWriter, request *http.Request) {
	var point domain.DriverPoint
	if json.NewDecoder(request.Body).Decode(&point) != nil || point.DriverID == "" {
		writeError(writer, http.StatusBadRequest, "invalid location")
		return
	}
	if err := router.service.Ingest(request.Context(), point); err != nil {
		writeError(writer, http.StatusInternalServerError, "could not save location")
		return
	}
	writeJSON(writer, http.StatusAccepted, point)
}

func (router *Router) nearby(writer http.ResponseWriter, request *http.Request) {
	query := request.URL.Query()
	latitude, latErr := strconv.ParseFloat(query.Get("latitude"), 64)
	longitude, lonErr := strconv.ParseFloat(query.Get("longitude"), 64)
	radius, radiusErr := strconv.ParseFloat(query.Get("radius_km"), 64)
	if latErr != nil || lonErr != nil || radiusErr != nil || radius < 0 {
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

func writeJSON(writer http.ResponseWriter, status int, value any) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(value)
}
func writeError(writer http.ResponseWriter, status int, message string) {
	writeJSON(writer, status, map[string]string{"error": message})
}
