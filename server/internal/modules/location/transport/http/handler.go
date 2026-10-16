package http

import (
	"errors"
	"net/http"
	"strconv"

	locationapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
)

type Handler struct {
	service *locationapp.LocationService
}

const _maxRoutePayloadBytes = 16 << 10

func NewHandler(service *locationapp.LocationService) *Handler {
	return &Handler{service: service}
}

func (handler *Handler) Nearby(writer http.ResponseWriter, request *http.Request) {
	coordinates, err := coordinatesFromQuery(request)
	if err != nil || !hasCoordinates(request) {
		response.Error(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}
	page := 1
	if rawPage := request.URL.Query().Get("page"); rawPage != "" {
		page, err = strconv.Atoi(rawPage)
		invalidPage := err != nil || page < 1 || page > 100
		if invalidPage {
			response.Error(writer, http.StatusBadRequest, "invalid page")
			return
		}
	}
	places, err := handler.service.Nearby(request.Context(), coordinates, page)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, map[string]any{"places": NewPlaceResponses(places), "page": page})
}

func (handler *Handler) Search(writer http.ResponseWriter, request *http.Request) {
	coordinates, err := coordinatesFromQuery(request)
	query := request.URL.Query().Get("q")
	if query == "" {
		query = request.URL.Query().Get("query")
	}
	invalidQuery := err != nil || !hasCoordinates(request) || !coordinates.Valid()
	if invalidQuery {
		response.Error(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}
	places, err := handler.service.Search(request.Context(), query, coordinates)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, map[string]any{"places": NewPlaceResponses(places)})
}

func (handler *Handler) Reverse(writer http.ResponseWriter, request *http.Request) {
	coordinates, err := coordinatesFromQuery(request)
	if err != nil || !hasCoordinates(request) {
		response.Error(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}
	place, err := handler.service.ReverseGeocode(request.Context(), coordinates)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, NewPlaceResponse(place))
}

func (handler *Handler) Route(writer http.ResponseWriter, request *http.Request) {
	var payload RouteRequest
	if err := decodeRouteRequest(writer, request, &payload); err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid route payload")
		return
	}
	options, err := payload.Options()
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid route options")
		return
	}
	route, err := handler.service.Route(
		request.Context(),
		payload.Origin.ToDomain(),
		payload.Destination.ToDomain(),
		options,
	)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, NewRouteResponse(route))
}

func (handler *Handler) Matrix(writer http.ResponseWriter, request *http.Request) {
	var payload MatrixRequest
	if sharedrequest.DecodeJSON(writer, request, &payload, _maxRoutePayloadBytes) != nil {
		response.Error(writer, http.StatusBadRequest, "invalid matrix payload")
		return
	}
	matrix, err := handler.service.Matrix(
		request.Context(),
		payload.DomainOrigin(),
		payload.DomainDestinations(),
	)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, NewMatrixResponse(matrix))
}

func decodeRouteRequest(writer http.ResponseWriter, request *http.Request, payload *RouteRequest) error {
	return sharedrequest.DecodeJSON(writer, request, payload, _maxRoutePayloadBytes)
}

func writeServiceError(writer http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, locationapp.ErrEmptySearch),
		errors.Is(err, locationapp.ErrSearchTooLong),
		errors.Is(err, locationapp.ErrInvalidCoordinates),
		errors.Is(err, locationapp.ErrInvalidNearbyPage),
		errors.Is(err, locationapp.ErrInvalidRouteOptions),
		errors.Is(err, locationapp.ErrInvalidMatrix):
		response.Error(writer, http.StatusBadRequest, "The location request is invalid.")
	default:
		response.Error(writer, http.StatusBadGateway, "Nearby locations are temporarily unavailable.")
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
