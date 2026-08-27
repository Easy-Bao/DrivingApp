package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service  *usecase.ChatService
	verifier *security.TokenManager
}

func NewHandler(service *usecase.ChatService, verifier *security.TokenManager) *Handler {
	return &Handler{service: service, verifier: verifier}
}

func (handler *Handler) CreateRoom(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok {
		writeError(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input struct {
		RideID string `json:"ride_id"`
	}
	if sharedrequest.DecodeJSON(writer, request, &input, 8<<10) != nil {
		writeError(writer, http.StatusBadRequest, "invalid chat room")
		return
	}
	if input.RideID == "" {
		writeError(writer, http.StatusBadRequest, "ride id is required")
		return
	}
	if err := handler.service.OpenRideRoom(request.Context(), input.RideID, identity); err != nil {
		status := http.StatusInternalServerError
		if err == domain.ErrInvalidRoom {
			status = http.StatusBadRequest
		} else if err == domain.ErrRoomConflict {
			status = http.StatusConflict
		} else if err == domain.ErrRoomLocked {
			status = http.StatusLocked
		} else if err == domain.ErrForbidden {
			status = http.StatusForbidden
		} else if err == domain.ErrRoomUnavailable {
			status = http.StatusServiceUnavailable
		}
		writeError(writer, status, "could not create chat room")
		return
	}
	writeJSON(writer, http.StatusCreated, map[string]any{"room_id": input.RideID, "status": "open"})
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
	identity, ok := middleware.IdentityFromRequest(request, handler.verifier)
	return identity.Subject, ok
}

func writeJSON(writer http.ResponseWriter, status int, value any) {
	response.JSON(writer, status, value)
}
func writeError(writer http.ResponseWriter, status int, message string) {
	response.Error(writer, status, message)
}
