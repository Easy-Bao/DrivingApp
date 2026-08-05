package handler

import (
	"encoding/json"
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/go-chi/chi/v5"
)

type Handler struct{ service *usecase.Service }

func NewHandler(service *usecase.Service) *Handler { return &Handler{service: service} }

func (handler *Handler) CreateRoom(writer http.ResponseWriter, request *http.Request) {
	var input struct {
		RoomID      string `json:"roomId"`
		RoomIDSnake string `json:"room_id"`
		PassengerID string `json:"passengerId"`
		DriverID    string `json:"driverId"`
	}
	if json.NewDecoder(http.MaxBytesReader(writer, request.Body, 8<<10)).Decode(&input) != nil {
		writeError(writer, http.StatusBadRequest, "invalid chat room")
		return
	}
	if input.RoomID == "" {
		input.RoomID = input.RoomIDSnake
	}
	if input.RoomID == "" {
		writeError(writer, http.StatusBadRequest, "room id is required")
		return
	}
	if err := handler.service.CreateRoom(request.Context(), input.RoomID, input.PassengerID, input.DriverID); err != nil {
		writeError(writer, http.StatusInternalServerError, "could not create chat room")
		return
	}
	writeJSON(writer, http.StatusCreated, map[string]any{"room_id": input.RoomID, "status": "open"})
}

func (handler *Handler) Messages(writer http.ResponseWriter, request *http.Request) {
	items, err := handler.service.Messages(request.Context(), chi.URLParam(request, "roomID"))
	if err != nil {
		writeError(writer, http.StatusInternalServerError, "could not load chat messages")
		return
	}
	result := make([]map[string]string, 0, len(items))
	for _, item := range items {
		result = append(result, map[string]string{"text": item.Body, "message": item.Body, "sender_id": item.SenderID, "senderId": item.SenderID, "created_at": item.CreatedAt, "createdAt": item.CreatedAt})
	}
	writeJSON(writer, http.StatusOK, map[string]any{"messages": result})
}

func (handler *Handler) Resolve(writer http.ResponseWriter, request *http.Request) {
	if err := handler.service.Resolve(request.Context(), chi.URLParam(request, "roomID")); err != nil {
		writeError(writer, http.StatusInternalServerError, "could not resolve chat room")
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"room_id": chi.URLParam(request, "roomID"), "status": "resolved"})
}

func writeJSON(writer http.ResponseWriter, status int, value any) {
	response.JSON(writer, status, value)
}
func writeError(writer http.ResponseWriter, status int, message string) {
	writeJSON(writer, status, map[string]string{"error": message})
}
