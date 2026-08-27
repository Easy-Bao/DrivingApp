package handler

import (
	"net/http"
	"strconv"
	"strings"

	ridecontext "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

type Handler struct {
	query    ridecontext.RideContextQuery
	verifier *security.TokenManager
}

func NewHandler(query ridecontext.RideContextQuery, verifier *security.TokenManager) *Handler {
	return &Handler{query: query, verifier: verifier}
}

func (handler *Handler) GetRideContext(writer http.ResponseWriter, request *http.Request) {
	passengerID, status := handler.passengerID(request)
	if status != 0 {
		writeError(writer, status, statusMessage(status))
		return
	}

	coordinates, err := coordinatesFromQuery(request)
	if err != nil {
		writeError(writer, http.StatusBadRequest, "invalid location coordinates")
		return
	}

	snapshot, err := handler.query.Load(request.Context(), passengerID, coordinates)
	if err != nil {
		writeError(writer, http.StatusBadGateway, "passenger ridecontext data unavailable")
		return
	}
	response.JSON(writer, http.StatusOK, toResponse(snapshot))
}

func (handler *Handler) passengerID(request *http.Request) (*int, int) {
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

func coordinatesFromQuery(request *http.Request) (*ridecontext.Coordinates, error) {
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
	coordinates := &ridecontext.Coordinates{
		Latitude:  latitude,
		Longitude: longitude,
	}
	if latitudeErr != nil || longitudeErr != nil || !coordinates.Valid() {
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

func toResponse(snapshot ridecontext.RideContextSnapshot) snapshotResponse {
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

func writeError(writer http.ResponseWriter, status int, message string) {
	response.Error(writer, status, message)
}
