package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

type Handler struct {
	service *application.StatsService
}

func NewHandler(service *application.StatsService) *Handler {
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

type statsResponse struct {
	Users           int `json:"users"`
	Rides           int `json:"rides"`
	DriverDocuments int `json:"driver_documents"`
}

func statsResponseFromDomain(stats domain.Stats) statsResponse {
	return statsResponse{
		Users:           stats.Users,
		Rides:           stats.Rides,
		DriverDocuments: stats.DriverDocuments,
	}
}
