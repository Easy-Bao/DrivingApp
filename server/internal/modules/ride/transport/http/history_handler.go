package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/go-chi/chi/v5"
	"net/http"
	"strconv"
)

func (handler *Handler) PassengerRides(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || targetID != actorID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	scope := "passenger-rides:" + strconv.Itoa(targetID)
	page, err := sharedrequest.ParseCursorPagination(r.URL.Query(), 25, 100, scope)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid pagination")
		return
	}
	items, err := handler.service.PassengerRides(r.Context(), targetID, domain.TripHistoryQuery{
		Limit: page.Limit, Offset: page.Offset, BeforeCreatedAt: page.BeforeCreatedAt, BeforeID: page.BeforeID,
	})
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Your trip history is temporarily unavailable.")
		return
	}
	writeRideHistoryPage(w, items, page, scope)
}

func (handler *Handler) PassengerActivitySummary(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	targetID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || targetID != actorID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	summary, err := handler.service.PassengerActivitySummary(r.Context(), targetID)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, "Passenger activity is temporarily unavailable.")
		return
	}
	response.JSON(w, http.StatusOK, NewPassengerActivitySummaryResponse(summary))
}

func (handler *Handler) DriverStats(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid driver id")
		return
	}
	if driverID != actorID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	stats, err := handler.service.DriverStats(r.Context(), driverID)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Driver statistics are temporarily unavailable.")
		return
	}
	response.JSON(w, http.StatusOK, NewDriverStatsResponse(stats))
}

func (handler *Handler) DriverEarnings(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil || driverID != actorID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	summary, err := handler.service.DriverEarnings(r.Context(), driverID)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, "Driver earnings are temporarily unavailable.")
		return
	}
	response.JSON(w, http.StatusOK, NewDriverEarningsResponse(summary))
}

func (handler *Handler) DriverTrips(w http.ResponseWriter, r *http.Request) {
	actorID, ok := handler.identity(r)
	if !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid driver id")
		return
	}
	if driverID != actorID {
		response.Error(w, http.StatusForbidden, "forbidden")
		return
	}
	activeOnly := false
	defaultLimit := 25
	maxLimit := 100
	switch r.URL.Query().Get("scope") {
	case "", "all":
	case "active":
		activeOnly = true
		defaultLimit = 10
		maxLimit = 20
	default:
		response.Error(w, http.StatusBadRequest, "invalid trip scope")
		return
	}
	scope := "driver-trips:" + strconv.Itoa(driverID) + ":" + strconv.FormatBool(activeOnly)
	page, err := sharedrequest.ParseCursorPagination(r.URL.Query(), defaultLimit, maxLimit, scope)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid pagination")
		return
	}
	items, err := handler.service.DriverTrips(r.Context(), driverID, domain.TripHistoryQuery{
		Limit: page.Limit, Offset: page.Offset, BeforeCreatedAt: page.BeforeCreatedAt, BeforeID: page.BeforeID, ActiveOnly: activeOnly,
	})
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Driver trip history is temporarily unavailable.")
		return
	}
	writeRideHistoryPage(w, items, page, scope)
}
