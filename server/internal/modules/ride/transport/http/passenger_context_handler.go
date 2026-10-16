package http

import (
	"net/http"
	"strconv"
	"strings"

	rideapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	ridecontextdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

type PassengerContextHandler struct {
	query    rideapp.Query
	verifier *security.TokenManager
}

type PassengerContextDependencies struct {
	Query         rideapp.Query
	Verifier      *security.TokenManager
	RouteSecurity *middleware.RouteSecurity
}

func NewPassengerContextHandler(dependencies PassengerContextDependencies) *PassengerContextHandler {
	return &PassengerContextHandler{query: dependencies.Query, verifier: dependencies.Verifier}
}

func (handler *PassengerContextHandler) GetRideContext(writer http.ResponseWriter, request *http.Request) {
	passengerID, status := handler.passengerID(request)
	if status != 0 {
		response.Error(writer, status, statusMessage(status))
		return
	}

	coordinates, err := coordinatesFromQuery(request)
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}

	snapshot, err := handler.query.Load(request.Context(), passengerID, coordinates)
	if err != nil {
		response.Error(writer, http.StatusBadGateway, "passenger ridecontext data unavailable")
		return
	}
	response.JSON(writer, http.StatusOK, toResponse(snapshot))
}

func (handler *PassengerContextHandler) passengerID(request *http.Request) (*int, int) {
	if request.Header.Get("Authorization") == "" {
		return nil, 0
	}
	identity, ok := middleware.IdentityFromRequest(request, handler.verifier)
	if !ok {
		return nil, http.StatusUnauthorized
	}
	if identity.Role != "" && identity.Role != "passenger" {
		return nil, http.StatusForbidden
	}
	passengerID, err := strconv.Atoi(identity.Subject)
	if err != nil || passengerID <= 0 {
		return nil, http.StatusUnauthorized
	}
	return &passengerID, 0
}

func coordinatesFromQuery(request *http.Request) (*ridecontextdomain.Coordinates, error) {
	query := request.URL.Query()
	latitudeValue := strings.TrimSpace(query.Get("lat"))
	longitudeValue := strings.TrimSpace(query.Get("lng"))
	if latitudeValue == "" && longitudeValue == "" {
		return nil, nil
	}
	if latitudeValue == "" || longitudeValue == "" {
		return nil, strconv.ErrSyntax
	}

	latitude, latitudeErr := strconv.ParseFloat(latitudeValue, 64)
	longitude, longitudeErr := strconv.ParseFloat(longitudeValue, 64)
	coordinates := &ridecontextdomain.Coordinates{
		Latitude:  latitude,
		Longitude: longitude,
	}
	invalidLatitude := latitudeErr != nil
	invalidLongitude := longitudeErr != nil
	invalidCoordinates := !coordinates.Valid()
	if invalidLatitude || invalidLongitude || invalidCoordinates {
		return nil, strconv.ErrSyntax
	}
	return coordinates, nil
}

type snapshotResponse struct {
	CurrentAddress  string                   `json:"current_address"`
	RecentLocations []recentLocationResponse `json:"recent_locations"`
}

type recentLocationResponse struct {
	Title     string  `json:"title"`
	Subtitle  string  `json:"subtitle"`
	Latitude  float64 `json:"lat"`
	Longitude float64 `json:"lng"`
}

func toResponse(snapshot ridecontextdomain.RideContextSnapshot) snapshotResponse {
	recentLocations := make([]recentLocationResponse, 0, len(snapshot.RecentLocations))
	for _, location := range snapshot.RecentLocations {
		recentLocations = append(recentLocations, recentLocationResponse{
			Title:     location.Title,
			Subtitle:  location.Subtitle,
			Latitude:  location.Latitude,
			Longitude: location.Longitude,
		})
	}
	return snapshotResponse{
		CurrentAddress:  snapshot.CurrentAddress,
		RecentLocations: recentLocations,
	}
}

func statusMessage(status int) string {
	if status == http.StatusForbidden {
		return "passenger access required"
	}
	return "unauthorized"
}
