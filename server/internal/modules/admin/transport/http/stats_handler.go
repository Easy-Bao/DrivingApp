package http

import (
	"net/http"

	adminapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
)

type Handler struct {
	service *adminapp.StatsService
}

func NewHandler(service *adminapp.StatsService) *Handler {
	return &Handler{service: service}
}

func (handler *Handler) Stats(w http.ResponseWriter, r *http.Request) {
	stats, err := handler.service.Stats(r.Context())
	if err != nil {
		response.Error(w, 500, "Dashboard statistics are temporarily unavailable.")
		return
	}
	response.JSON(w, 200, statsResponseFromDomain(stats))
}
