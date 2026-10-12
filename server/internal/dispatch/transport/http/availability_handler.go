package http

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

func (handler *Handler) OnlineDrivers(w http.ResponseWriter, r *http.Request) {
	if _, ok := handler.identity(r); !ok {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	driverIDs, err := driverIDsFromQuery(r)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "driver ids are required")
		return
	}
	items, err := handler.availability.OnlineDrivers(r.Context(), driverIDs)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, "driver availability unavailable")
		return
	}
	response.JSON(w, http.StatusOK, dto.NewOnlineDriverResponses(items))
}

func (handler *Handler) PublicDriverSummaries(w http.ResponseWriter, r *http.Request) {
	limit := 5
	if r.URL.Query().Has("limit") {
		var err error
		limit, err = strconv.Atoi(r.URL.Query().Get("limit"))
		invalidLimit := err != nil || limit <= 0 || limit > 20
		if invalidLimit {
			response.Error(w, http.StatusBadRequest, "invalid limit")
			return
		}
	}
	summaries, err := handler.availability.PublicDriverSummaries(r.Context(), limit)
	if err != nil {
		response.Error(w, http.StatusServiceUnavailable, "driver availability unavailable")
		return
	}
	response.JSON(w, http.StatusOK, dto.NewPublicDriverSummaryResponses(summaries))
}

func driverIDsFromQuery(request *http.Request) ([]int, error) {
	values := strings.Split(request.URL.Query().Get("ids"), ",")
	if len(values) == 0 || len(values) > 20 {
		return nil, errors.New("invalid driver ids")
	}
	ids := make([]int, 0, len(values))
	seen := make(map[int]struct{}, len(values))
	for _, value := range values {
		id, err := strconv.Atoi(strings.TrimSpace(value))
		if err != nil || id <= 0 {
			return nil, errors.New("invalid driver id")
		}
		if _, exists := seen[id]; exists {
			continue
		}
		seen[id] = struct{}{}
		ids = append(ids, id)
	}
	if len(ids) == 0 {
		return nil, errors.New("driver ids are required")
	}
	return ids, nil
}
