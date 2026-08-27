package handler

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

type Handler struct {
	service *usecase.Service
}

func NewHandler(service *usecase.Service) *Handler {
	return &Handler{service: service}
}
func (handler *Handler) Stats(w http.ResponseWriter, r *http.Request) {
	stats, err := handler.service.DashboardStats(r.Context())
	if err != nil {
		writeError(w, 500, "Dashboard statistics are temporarily unavailable.")
		return
	}
	writeJSON(w, 200, stats)
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	response.JSON(w, status, value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	response.Error(w, status, message)
}
