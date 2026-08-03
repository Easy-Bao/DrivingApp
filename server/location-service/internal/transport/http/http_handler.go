package http

import (
	"context"
	"encoding/json"
	"errors"
	"location-service/internal/usecase"
	"net"
	"net/http"
	"strconv"
)

type HTTPHandler struct {
	useCase usecase.LocationUseCase
}

func NewHTTPHandler(uc usecase.LocationUseCase) *HTTPHandler {
	return &HTTPHandler{useCase: uc}
}

func (h *HTTPHandler) RegisterRoutes(router *http.ServeMux) {
	router.HandleFunc("GET /places/search", h.SearchPlaces)
	router.HandleFunc("GET /places/reverse", h.ReverseGeocode)
	router.HandleFunc("GET /places/nearby", h.GetNearbyPois)
	router.HandleFunc("POST /places/route", h.GetRoute)
}

func (h *HTTPHandler) SearchPlaces(writer http.ResponseWriter, request *http.Request) {
	query := request.URL.Query().Get("query")
	userLat, _ := strconv.ParseFloat(request.URL.Query().Get("userLat"), 64)
	userLng, _ := strconv.ParseFloat(request.URL.Query().Get("userLng"), 64)

	places, err := h.useCase.SearchPlaces(request.Context(), query, userLat, userLng)
	if err != nil {
		writeLocationError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]interface{}{
		"status": "success",
		"places": places,
	})
}

func (h *HTTPHandler) ReverseGeocode(writer http.ResponseWriter, request *http.Request) {
	lat, err1 := strconv.ParseFloat(request.URL.Query().Get("lat"), 64)
	lng, err2 := strconv.ParseFloat(request.URL.Query().Get("lng"), 64)
	if err1 != nil || err2 != nil {
		writeJSON(writer, http.StatusBadRequest, map[string]string{"error": "Invalid lat or lng parameters"})
		return
	}

	place, err := h.useCase.ReverseGeocode(request.Context(), lat, lng)
	if err != nil {
		writeLocationError(writer, err)
		return
	}

	writeJSON(writer, http.StatusOK, place)
}

func (h *HTTPHandler) GetNearbyPois(writer http.ResponseWriter, request *http.Request) {
	lat, err1 := strconv.ParseFloat(request.URL.Query().Get("lat"), 64)
	lng, err2 := strconv.ParseFloat(request.URL.Query().Get("lng"), 64)
	if err1 != nil || err2 != nil {
		writeJSON(writer, http.StatusBadRequest, map[string]string{"error": "Invalid lat or lng parameters"})
		return
	}
	page, _ := strconv.Atoi(request.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}

	places, err := h.useCase.GetNearbyPois(request.Context(), lat, lng, page)
	if err != nil {
		writeLocationError(writer, err)
		return
	}

	writeJSON(writer, http.StatusOK, map[string]interface{}{
		"status": "success",
		"places": places,
	})
}

type RouteRequest struct {
	OriginLat float64 `json:"originLat"`
	OriginLng float64 `json:"originLng"`
	DestLat   float64 `json:"destLat"`
	DestLng   float64 `json:"destLng"`
}

func (h *HTTPHandler) GetRoute(writer http.ResponseWriter, request *http.Request) {
	var req RouteRequest
	decoder := json.NewDecoder(http.MaxBytesReader(writer, request.Body, 16<<10))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&req); err != nil {
		writeJSON(writer, http.StatusBadRequest, map[string]string{"error": "Invalid route payload"})
		return
	}

	route, err := h.useCase.GetRoute(request.Context(), req.OriginLat, req.OriginLng, req.DestLat, req.DestLng)
	if err != nil {
		writeLocationError(writer, err)
		return
	}

	writeJSON(writer, http.StatusOK, route)
}

func writeLocationError(writer http.ResponseWriter, err error) {
	status := http.StatusInternalServerError
	var networkError net.Error
	if errors.Is(err, context.DeadlineExceeded) || errors.As(err, &networkError) && networkError.Timeout() {
		status = http.StatusGatewayTimeout
	}
	writeJSON(writer, status, map[string]string{"error": "Location provider is temporarily unavailable"})
}

func writeJSON(writer http.ResponseWriter, status int, value interface{}) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	if err := json.NewEncoder(writer).Encode(value); err != nil {
		return
	}
}
