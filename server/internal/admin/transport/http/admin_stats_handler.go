package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

type Handler struct {
	service *usecase.DashboardStatsService
}

func NewHandler(service *usecase.DashboardStatsService) *Handler {
	return &Handler{service: service}
}
func (handler *Handler) Stats(w http.ResponseWriter, r *http.Request) {
	stats, err := handler.service.DashboardStats(r.Context())
	if err != nil {
		response.Error(w, 500, "Dashboard statistics are temporarily unavailable.")
		return
	}
	response.JSON(w, 200, stats)
}
