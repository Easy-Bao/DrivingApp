package ws

import (
	"context"
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
)

type EventHandler struct{ service *usecase.Service }

func NewEventHandler(service *usecase.Service) *EventHandler { return &EventHandler{service: service} }
func (handler *EventHandler) Handle(message []byte) error {
	var event struct {
		Type      string  `json:"type"`
		DriverID  string  `json:"driver_id"`
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	}
	if err := json.Unmarshal(message, &event); err != nil || event.Type != "LOCATION_UPDATE" {
		return nil
	}
	return handler.service.Ingest(context.Background(), domain.DriverPoint{DriverID: event.DriverID, Latitude: event.Latitude, Longitude: event.Longitude})
}
