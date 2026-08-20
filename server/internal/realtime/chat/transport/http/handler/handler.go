package handler

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service  *usecase.Service
	verifier *token.Verifier
}

func NewHandler(service *usecase.Service, verifier *token.Verifier) *Handler {
	return &Handler{service: service, verifier: verifier}
}

func (handler *Handler) CreateRoom(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok {
		writeError(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
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
	if identity != input.PassengerID && identity != input.DriverID {
		writeError(writer, http.StatusForbidden, "chat room access denied")
		return
	}
	if err := handler.service.CreateRoom(request.Context(), input.RoomID, input.PassengerID, input.DriverID); err != nil {
		status := http.StatusInternalServerError
		if err == domain.ErrInvalidRoom {
			status = http.StatusBadRequest
		} else if err == domain.ErrRoomConflict {
			status = http.StatusConflict
		} else if err == domain.ErrForbidden {
			status = http.StatusForbidden
		} else if err == domain.ErrRoomUnavailable {
			status = http.StatusServiceUnavailable
		}
		writeError(writer, status, "could not create chat room")
		return
	}
	writeJSON(writer, http.StatusCreated, map[string]any{"room_id": input.RoomID, "status": "open"})
}

func (handler *Handler) Messages(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok {
		writeError(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	items, err := handler.service.MessagesForUser(request.Context(), chi.URLParam(request, "roomID"), identity)
	if err != nil {
		status := http.StatusInternalServerError
		if err == domain.ErrForbidden {
			status = http.StatusForbidden
		}
		writeError(writer, status, "could not load chat messages")
		return
	}
	result := make([]map[string]string, 0, len(items))
	for _, item := range items {
		result = append(result, map[string]string{"text": item.Body, "message": item.Body, "sender_id": item.SenderID, "senderId": item.SenderID, "created_at": item.CreatedAt, "createdAt": item.CreatedAt})
	}
	writeJSON(writer, http.StatusOK, map[string]any{"messages": result})
}

func (handler *Handler) Resolve(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok {
		writeError(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	roomID := chi.URLParam(request, "roomID")
	if err := handler.service.ResolveForUser(request.Context(), roomID, identity); err != nil {
		status := http.StatusInternalServerError
		if err == domain.ErrForbidden {
			status = http.StatusForbidden
		}
		writeError(writer, status, "could not resolve chat room")
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"room_id": roomID, "status": "resolved"})
}

func (handler *Handler) identity(request *http.Request) (string, bool) {
	const prefix = "Bearer "
	header := request.Header.Get("Authorization")
	if handler.verifier == nil || len(header) <= len(prefix) || !strings.HasPrefix(header, prefix) {
		return "", false
	}
	subject, err := handler.verifier.Verify(header[len(prefix):])
	return subject, err == nil && subject != ""
}

func writeJSON(writer http.ResponseWriter, status int, value any) {
	response.JSON(writer, status, value)
}
func writeError(writer http.ResponseWriter, status int, message string) {
	writeJSON(writer, status, map[string]string{"error": message})
}
