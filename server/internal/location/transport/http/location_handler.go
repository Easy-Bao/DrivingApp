package http

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

type Handler struct {
	service *usecase.LocationService
}

const maxRoutePayloadBytes = 16 << 10

func NewHandler(service *usecase.LocationService) *Handler {
	return &Handler{service: service}
}

func (handler *Handler) Nearby(writer http.ResponseWriter, request *http.Request) {
	coordinates, err := coordinatesFromQuery(request)
	if err != nil || !hasCoordinates(request) {
		writeError(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}
	page := 1
	if rawPage := request.URL.Query().Get("page"); rawPage != "" {
		page, err = strconv.Atoi(rawPage)
		if err != nil || page < 1 || page > 100 {
			writeError(writer, http.StatusBadRequest, "invalid page")
			return
		}
	}
	places, err := handler.service.Nearby(request.Context(), coordinates, page)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"places": places, "page": page})
}

func (handler *Handler) Search(writer http.ResponseWriter, request *http.Request) {
	coordinates, _ := coordinatesFromQuery(request)
	query := request.URL.Query().Get("q")
	if query == "" {
		query = request.URL.Query().Get("query")
	}
	coordinatesErr := coordinatesError(request)
	if coordinatesErr != nil {
		writeError(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}
	places, err := handler.service.Search(request.Context(), query, coordinates)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"places": places})
}

func (handler *Handler) Reverse(writer http.ResponseWriter, request *http.Request) {
	coordinates, err := coordinatesFromQuery(request)
	if err != nil || !hasCoordinates(request) {
		writeError(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}
	place, err := handler.service.ReverseGeocode(request.Context(), coordinates)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, place)
}

func (handler *Handler) Route(writer http.ResponseWriter, request *http.Request) {
	var payload dto.RouteRequest
	if err := decodeRouteRequest(writer, request, &payload); err != nil {
		writeError(writer, http.StatusBadRequest, "invalid route payload")
		return
	}
	options, err := payload.Options()
	if err != nil {
		writeError(writer, http.StatusBadRequest, "invalid route options")
		return
	}
	route, err := handler.service.Route(request.Context(), payload.Origin, payload.Destination, options)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, route)
}

func (handler *Handler) Matrix(writer http.ResponseWriter, request *http.Request) {
	var payload dto.MatrixRequest
	if sharedrequest.DecodeJSON(writer, request, &payload, maxRoutePayloadBytes) != nil {
		writeError(writer, http.StatusBadRequest, "invalid matrix payload")
		return
	}
	matrix, err := handler.service.Matrix(request.Context(), payload.Origin, payload.Destinations)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, matrix)
}

func decodeRouteRequest(writer http.ResponseWriter, request *http.Request, payload *dto.RouteRequest) error {
	return sharedrequest.DecodeJSON(writer, request, payload, maxRoutePayloadBytes)
}

func writeServiceError(writer http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, usecase.ErrEmptySearch),
		errors.Is(err, usecase.ErrSearchTooLong),
		errors.Is(err, usecase.ErrInvalidCoordinates),
		errors.Is(err, usecase.ErrInvalidNearbyPage),
		errors.Is(err, usecase.ErrInvalidRouteOptions),
		errors.Is(err, usecase.ErrInvalidMatrix):
		writeError(writer, http.StatusBadRequest, "The location request is invalid.")
	default:
		writeError(writer, http.StatusBadGateway, "Nearby locations are temporarily unavailable.")
	}
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

func coordinatesError(request *http.Request) error {
	query := request.URL.Query()
	hasLatitude := query.Get("lat") != "" || query.Get("userLat") != ""
	hasLongitude := query.Get("lng") != "" || query.Get("userLng") != ""
	if hasLatitude != hasLongitude {
		return errors.New("incomplete coordinates")
	}
	if !hasLatitude {
		return nil
	}
	coordinates, err := coordinatesFromQuery(request)
	if err != nil || !coordinates.Valid() {
		return errors.New("invalid coordinates")
	}
	return nil
}

func writeJSON(writer http.ResponseWriter, status int, value any) {
	response.JSON(writer, status, value)
}

func writeError(writer http.ResponseWriter, status int, message string) {
	response.Error(writer, status, message)
}
