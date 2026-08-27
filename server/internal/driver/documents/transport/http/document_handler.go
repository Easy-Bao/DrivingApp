package http

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http/dto"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/go-chi/chi/v5"
)

const maxReviewPayloadBytes int64 = 1 << 10

type Handler struct {
	service *usecase.DocumentService
}

func NewHandler(service *usecase.DocumentService) *Handler {
	return &Handler{service: service}
}

func (handler *Handler) Upload(writer http.ResponseWriter, request *http.Request) {
	driverID, ok := actorID(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	limit := handler.service.MaxDocumentBytes()
	content, err := io.ReadAll(io.LimitReader(request.Body, limit+1))
	if err != nil {
		var maxBytesError *http.MaxBytesError
		if errors.As(err, &maxBytesError) {
			response.Error(writer, http.StatusRequestEntityTooLarge, "The document is too large.")
			return
		}
		response.Error(writer, http.StatusBadRequest, "The document body could not be read.")
		return
	}
	if int64(len(content)) > limit {
		response.Error(writer, http.StatusRequestEntityTooLarge, "The document is too large.")
		return
	}
	item, err := handler.service.Upload(
		request.Context(),
		driverID,
		request.URL.Query().Get("type"),
		request.Header.Get("Content-Type"),
		content,
	)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	response.JSON(writer, http.StatusCreated, item)
}

func (handler *Handler) Status(writer http.ResponseWriter, request *http.Request) {
	driverID, ok := actorID(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	items, err := handler.service.Status(request.Context(), driverID)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, map[string]any{"documents": items})
}

func (handler *Handler) DriverContent(writer http.ResponseWriter, request *http.Request) {
	driverID, ok := actorID(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	documentID, err := documentID(request)
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid document id")
		return
	}
	content, err := handler.service.DriverContent(request.Context(), driverID, documentID)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	writeDocumentContent(writer, content)
}

func (handler *Handler) ReviewQueue(writer http.ResponseWriter, request *http.Request) {
	status := domain.Status(request.URL.Query().Get("status"))
	if status == "" {
		status = domain.Pending
	}
	page, err := sharedrequest.ParseOffsetPagination(request.URL.Query(), 25, 100)
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid pagination")
		return
	}
	items, err := handler.service.ReviewQueue(request.Context(), status, page.Limit, page.Offset)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, response.NewOffsetPage(items, page.Limit, page.Offset))
}

func (handler *Handler) Review(writer http.ResponseWriter, request *http.Request) {
	reviewerID, ok := actorID(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	documentID, err := documentID(request)
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid document id")
		return
	}
	var payload dto.ReviewRequest
	if sharedrequest.DecodeJSON(writer, request, &payload, maxReviewPayloadBytes) != nil {
		response.Error(writer, http.StatusBadRequest, "invalid review payload")
		return
	}
	status, err := domain.ParseReviewStatus(payload.Status)
	if err != nil {
		response.Error(writer, http.StatusUnprocessableEntity, "invalid review status")
		return
	}
	item, err := handler.service.Review(request.Context(), documentID, reviewerID, status)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	response.JSON(writer, http.StatusOK, item)
}

func (handler *Handler) AdminContent(writer http.ResponseWriter, request *http.Request) {
	documentID, err := documentID(request)
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid document id")
		return
	}
	content, err := handler.service.AdminContent(request.Context(), documentID)
	if err != nil {
		writeServiceError(writer, err)
		return
	}
	writeDocumentContent(writer, content)
}

func actorID(request *http.Request) (int, bool) {
	principal, ok := middleware.PrincipalFromRequest(request)
	return principal.UserID, ok
}

func documentID(request *http.Request) (int, error) {
	id, err := strconv.Atoi(chi.URLParam(request, "id"))
	if err != nil || id <= 0 {
		return 0, domain.ErrInvalidDocument
	}
	return id, nil
}

func writeDocumentContent(writer http.ResponseWriter, content domain.Content) {
	writer.Header().Set("Cache-Control", "private, no-store")
	writer.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%q", documentFilename(content.Document)))
	writer.Header().Set("Content-Length", strconv.Itoa(len(content.Bytes)))
	writer.Header().Set("Content-Type", content.Document.ContentType)
	writer.WriteHeader(http.StatusOK)
	_, _ = writer.Write(content.Bytes)
}

func documentFilename(document domain.Document) string {
	extension := ".bin"
	switch document.ContentType {
	case "application/pdf":
		extension = ".pdf"
	case "image/jpeg":
		extension = ".jpg"
	case "image/png":
		extension = ".png"
	}
	return string(document.Type) + extension
}

func writeServiceError(writer http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, domain.ErrInvalidDocumentType), errors.Is(err, domain.ErrInvalidDocument):
		response.Error(writer, http.StatusUnprocessableEntity, "The document request is invalid.")
	case errors.Is(err, domain.ErrUnsupportedContentType):
		response.Error(writer, http.StatusUnsupportedMediaType, "Only PDF, JPEG, and PNG documents are supported.")
	case errors.Is(err, domain.ErrDocumentNotFound):
		response.Error(writer, http.StatusNotFound, "document not found")
	case errors.Is(err, domain.ErrDocumentFinalized):
		response.Error(writer, http.StatusConflict, "The document review is already finalized.")
	case errors.Is(err, domain.ErrDocumentCorrupt):
		response.Error(writer, http.StatusServiceUnavailable, "The document content is unavailable.")
	default:
		response.Error(writer, http.StatusInternalServerError, "The document service is temporarily unavailable.")
	}
}
