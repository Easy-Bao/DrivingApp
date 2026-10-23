package http

import (
	"errors"
	"io"
	"net/http"

	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service  *application.Service
	verifier *security.TokenManager
}

type Dependencies struct {
	Service       *application.Service
	Verifier      *security.TokenManager
	RouteSecurity *middleware.RouteSecurity
}

func NewHandler(dependencies Dependencies) *Handler {
	return &Handler{service: dependencies.Service, verifier: dependencies.Verifier}
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
	response.JSON(writer, http.StatusOK, map[string]any{"messages": NewMessageResponses(items)})
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
	case errors.Is(err, domain.ErrInvalidRoom), errors.Is(err, domain.ErrInvalidMessage):
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

func (handler *Handler) SendImage(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	request.Body = http.MaxBytesReader(writer, request.Body, application.MaxImageBytes+(64<<10))
	if err := request.ParseMultipartForm(application.MaxImageBytes); err != nil {
		response.Error(writer, http.StatusBadRequest, "Choose a JPEG or PNG picture up to 5 MB.")
		return
	}
	defer request.MultipartForm.RemoveAll()
	file, _, err := request.FormFile("photo")
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "picture is required")
		return
	}
	defer file.Close()
	content, err := io.ReadAll(io.LimitReader(file, application.MaxImageBytes+1))
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "could not read picture")
		return
	}
	message, err := handler.service.SendImage(request.Context(), chi.URLParam(request, "roomID"), identity, content)
	if err != nil {
		response.Error(writer, chatErrorStatus(err), "could not send picture")
		return
	}
	response.JSON(writer, http.StatusCreated, NewMessageResponse(message))
}

func (handler *Handler) Image(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	content, contentType, err := handler.service.Image(request.Context(), chi.URLParam(request, "roomID"), identity, chi.URLParam(request, "messageID"))
	if err != nil {
		response.Error(writer, chatErrorStatus(err), "could not load picture")
		return
	}
	writer.Header().Set("Content-Type", contentType)
	writer.Header().Set("Cache-Control", "private, no-store")
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	writer.Write(content)
}

func (handler *Handler) MarkRead(writer http.ResponseWriter, request *http.Request) {
	identity, ok := handler.identity(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input struct {
		MessageID string `json:"message_id"`
	}
	if err := sharedrequest.DecodeJSON(writer, request, &input, 8<<10); err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid read receipt")
		return
	}
	if err := handler.service.MarkRead(request.Context(), chi.URLParam(request, "roomID"), identity, input.MessageID); err != nil {
		response.Error(writer, chatErrorStatus(err), "could not save read receipt")
		return
	}
	writer.WriteHeader(http.StatusNoContent)
}
