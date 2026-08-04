package httptransport

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service *usecase.Service
}

func NewHandler(service *usecase.Service) *Handler {
	return &Handler{service: service}
}

func (handler *Handler) RegisterRoutes(router chi.Router) {
	router.Get("/api/v1/location/search", handler.search)
	router.Get("/api/v1/location/nearby", handler.nearby)
	router.Get("/api/v1/location/reverse", handler.reverse)
	router.Post("/api/v1/location/route", handler.route)
	for _, prefix := range []string{"/location", "/places"} {
		router.Get(prefix+"/search", handler.search)
		router.Get(prefix+"/nearby", handler.nearby)
		router.Get(prefix+"/reverse", handler.reverse)
		router.Post(prefix+"/route", handler.route)
	}
}

func (handler *Handler) nearby(writer http.ResponseWriter, request *http.Request) {
	coordinates, err := coordinatesFromQuery(request)
	if err != nil || !hasCoordinates(request) {
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
	coordinates, _ := coordinatesFromQuery(request)
	query := request.URL.Query().Get("q")
	if query == "" {
		query = request.URL.Query().Get("query")
	}
	places, err := handler.service.Search(request.Context(), query, coordinates)
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
	if err != nil || !hasCoordinates(request) {
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

func (handler *Handler) route(writer http.ResponseWriter, request *http.Request) {
	var payload dto.RouteRequest
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
	query := request.URL.Query()
	latitudeValue := query.Get("lat")
	longitudeValue := query.Get("lng")
	if latitudeValue == "" {
		latitudeValue = query.Get("userLat")
	}
	if longitudeValue == "" {
		longitudeValue = query.Get("userLng")
	}
	if latitudeValue == "" && longitudeValue == "" {
		return domain.Coordinates{}, nil
	}
	latitude, latitudeErr := strconv.ParseFloat(latitudeValue, 64)
	longitude, longitudeErr := strconv.ParseFloat(longitudeValue, 64)
	if latitudeErr != nil || longitudeErr != nil {
		return domain.Coordinates{}, errors.New("invalid coordinates")
	}
	return domain.Coordinates{Latitude: latitude, Longitude: longitude}, nil
}

func hasCoordinates(request *http.Request) bool {
	query := request.URL.Query()
	return (query.Get("lat") != "" || query.Get("userLat") != "") && (query.Get("lng") != "" || query.Get("userLng") != "")
}

func writeJSON(writer http.ResponseWriter, status int, value any) {
	response.JSON(writer, status, value)
}

func writeError(writer http.ResponseWriter, status int, message string) {
	writeJSON(writer, status, map[string]string{"error": message})
}
