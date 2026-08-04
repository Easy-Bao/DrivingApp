package httptransport

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
)

type Handler struct {
	service *usecase.Service
}

func NewHandler(service *usecase.Service) *Handler {
	return &Handler{service: service}
}

func (handler *Handler) RegisterRoutes(router *http.ServeMux) {
	router.HandleFunc("GET /api/v1/location/search", handler.search)
	router.HandleFunc("GET /api/v1/location/nearby", handler.nearby)
	router.HandleFunc("GET /api/v1/location/reverse", handler.reverse)
	router.HandleFunc("POST /api/v1/location/route", handler.route)
}

func (handler *Handler) nearby(writer http.ResponseWriter, request *http.Request) {
	coordinates, err := coordinatesFromQuery(request)
	if err != nil {
		writeError(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}
	page := 1
	if rawPage := request.URL.Query().Get("page"); rawPage != "" {
		page, err = strconv.Atoi(rawPage)
		if err != nil || page < 1 {
			writeError(writer, http.StatusBadRequest, "invalid page")
			return
		}
	}
	places, err := handler.service.Nearby(request.Context(), coordinates, page)
	if err != nil {
		writeError(writer, http.StatusBadGateway, "location provider unavailable")
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"places": places, "page": page})
}

func (handler *Handler) search(writer http.ResponseWriter, request *http.Request) {
	coordinates, err := coordinatesFromQuery(request)
	if err != nil {
		writeError(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}
	places, err := handler.service.Search(request.Context(), request.URL.Query().Get("q"), coordinates)
	if errors.Is(err, usecase.ErrEmptySearch) {
		writeError(writer, http.StatusBadRequest, err.Error())
		return
	}
	if err != nil {
		writeError(writer, http.StatusBadGateway, "location provider unavailable")
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"places": places})
}

func (handler *Handler) reverse(writer http.ResponseWriter, request *http.Request) {
	coordinates, err := coordinatesFromQuery(request)
	if err != nil {
		writeError(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}
	place, err := handler.service.ReverseGeocode(request.Context(), coordinates)
	if err != nil {
		writeError(writer, http.StatusBadGateway, "location provider unavailable")
		return
	}
	writeJSON(writer, http.StatusOK, place)
}

type routeRequest struct {
	Origin      domain.Coordinates `json:"origin"`
	Destination domain.Coordinates `json:"destination"`
}

func (handler *Handler) route(writer http.ResponseWriter, request *http.Request) {
	var payload routeRequest
	decoder := json.NewDecoder(http.MaxBytesReader(writer, request.Body, 16<<10))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&payload); err != nil {
		writeError(writer, http.StatusBadRequest, "invalid route payload")
		return
	}
	route, err := handler.service.Route(request.Context(), payload.Origin, payload.Destination)
	if err != nil {
		writeError(writer, http.StatusBadGateway, "location provider unavailable")
		return
	}
	writeJSON(writer, http.StatusOK, route)
}

func coordinatesFromQuery(request *http.Request) (domain.Coordinates, error) {
	latitude, latitudeErr := strconv.ParseFloat(request.URL.Query().Get("lat"), 64)
	longitude, longitudeErr := strconv.ParseFloat(request.URL.Query().Get("lng"), 64)
	if latitudeErr != nil || longitudeErr != nil {
		return domain.Coordinates{}, errors.New("invalid coordinates")
	}
	return domain.Coordinates{Latitude: latitude, Longitude: longitude}, nil
}

func writeJSON(writer http.ResponseWriter, status int, value any) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(value)
}

func writeError(writer http.ResponseWriter, status int, message string) {
	writeJSON(writer, status, map[string]string{"error": message})
}
