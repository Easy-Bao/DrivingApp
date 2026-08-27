package http

import (
	"errors"
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
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input struct {
		RideID string `json:"ride_id"`
	}
	if sharedrequest.DecodeJSON(writer, request, &input, 8<<10) != nil {
		response.Error(writer, http.StatusBadRequest, "invalid chat room")
		return
	}
	if input.RideID == "" {
		response.Error(writer, http.StatusBadRequest, "ride id is required")
		return
	}
	if err := handler.service.OpenRideRoom(request.Context(), input.RideID, identity); err != nil {
		response.Error(writer, chatErrorStatus(err), "could not create chat room")
		return
	}
	response.JSON(writer, http.StatusCreated, map[string]any{"room_id": input.RideID, "status": "open"})
}

func (handler *Handler) Messages(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	items, err := handler.service.MessagesForUser(request.Context(), chi.URLParam(request, "roomID"), identity)
	if err != nil {
		response.Error(writer, chatErrorStatus(err), "could not load chat messages")
		return
	}
	result := make([]map[string]string, 0, len(items))
	for _, item := range items {
		result = append(result, map[string]string{"text": item.Body, "message": item.Body, "sender_id": item.SenderID, "senderId": item.SenderID, "created_at": item.CreatedAt, "createdAt": item.CreatedAt})
	}
	response.JSON(writer, http.StatusOK, map[string]any{"messages": result})
}

func (handler *Handler) Resolve(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	roomID := chi.URLParam(request, "roomID")
	if err := handler.service.ResolveForUser(request.Context(), roomID, identity); err != nil {
		response.Error(writer, chatErrorStatus(err), "could not resolve chat room")
		return
	}
	response.JSON(writer, http.StatusOK, map[string]any{"room_id": roomID, "status": "resolved"})
}

func (handler *Handler) identity(request *http.Request) (string, bool) {
	identity, ok := middleware.IdentityFromRequest(request, handler.verifier)
	return identity.Subject, ok
}

func chatErrorStatus(err error) int {
	switch {
	case errors.Is(err, domain.ErrInvalidRoom):
		return http.StatusBadRequest
	case errors.Is(err, domain.ErrRoomConflict):
		return http.StatusConflict
	case errors.Is(err, domain.ErrRoomLocked):
		return http.StatusLocked
	case errors.Is(err, domain.ErrForbidden):
		return http.StatusForbidden
	case errors.Is(err, domain.ErrRoomUnavailable):
		return http.StatusServiceUnavailable
	default:
		return http.StatusInternalServerError
	}
}
