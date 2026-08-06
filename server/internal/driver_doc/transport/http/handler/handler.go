package handler

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
	"io"
	"net/http"
	"strconv"
)

type Handler struct {
	service    *usecase.Service
	verifier   *token.Verifier
	authorizer *security.AdminAuthorizer
}

func NewHandler(service *usecase.Service, verifier *token.Verifier, authorizer *security.AdminAuthorizer) *Handler {
	return &Handler{service: service, verifier: verifier, authorizer: authorizer}
}
func (handler *Handler) identity(r *http.Request) (int, bool) {
	raw := r.Header.Get("Authorization")
	if len(raw) < 7 {
		return 0, false
	}
	subject, err := handler.verifier.Verify(raw[7:])
	id, parseErr := strconv.Atoi(subject)
	return id, err == nil && parseErr == nil
}
func (handler *Handler) Upload(w http.ResponseWriter, r *http.Request) {
	id, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	documentType := r.URL.Query().Get("type")
	if documentType == "" {
		documentType = "document"
	}
	content, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 5<<20))
	if err != nil {
		writeError(w, 400, "invalid document")
		return
	}
	item, err := handler.service.Upload(r.Context(), id, documentType, content)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 201, item)
}
func (handler *Handler) Status(w http.ResponseWriter, r *http.Request) {
	id, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	items, err := handler.service.Status(r.Context(), id)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]any{"documents": items})
}
func (handler *Handler) Review(w http.ResponseWriter, r *http.Request) {
	identity, ok := handler.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	if !handler.authorizer.IsAdmin(strconv.Itoa(identity)) {
		writeError(w, 403, "forbidden")
		return
	}
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, 400, "invalid document id")
		return
	}
	status := domain.Status(r.URL.Query().Get("status"))
	if status != domain.Approved && status != domain.Rejected {
		writeError(w, 400, "invalid review status")
		return
	}
	item, err := handler.service.Review(r.Context(), id, status)
	if err != nil {
		writeError(w, 404, "document not found")
		return
	}
	writeJSON(w, 200, item)
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	response.JSON(w, status, value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
