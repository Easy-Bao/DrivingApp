package http

import (
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/usecase"
	"io"
	"net/http"
	"strconv"
)

type Router struct {
	service  *usecase.Service
	verifier *token.Verifier
}

func NewRouter(service *usecase.Service, verifier *token.Verifier) *Router {
	return &Router{service: service, verifier: verifier}
}
func (router *Router) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/driver/documents", router.upload)
	mux.HandleFunc("GET /api/v1/driver/documents/status", router.status)
	mux.HandleFunc("PATCH /api/v1/admin/documents/{id}/review", router.review)
}
func (router *Router) identity(r *http.Request) (int, bool) {
	raw := r.Header.Get("Authorization")
	if len(raw) < 7 {
		return 0, false
	}
	subject, err := router.verifier.Verify(raw[7:])
	id, parseErr := strconv.Atoi(subject)
	return id, err == nil && parseErr == nil
}
func (router *Router) upload(w http.ResponseWriter, r *http.Request) {
	id, ok := router.identity(r)
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
	item, err := router.service.Upload(r.Context(), id, documentType, content)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 201, item)
}
func (router *Router) status(w http.ResponseWriter, r *http.Request) {
	id, ok := router.identity(r)
	if !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	items, err := router.service.Status(r.Context(), id)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}
	writeJSON(w, 200, map[string]any{"documents": items})
}
func (router *Router) review(w http.ResponseWriter, r *http.Request) {
	if _, ok := router.identity(r); !ok {
		writeError(w, 401, "unauthorized")
		return
	}
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		writeError(w, 400, "invalid document id")
		return
	}
	status := domain.Status(r.URL.Query().Get("status"))
	if status != domain.Approved && status != domain.Rejected {
		writeError(w, 400, "invalid review status")
		return
	}
	item, err := router.service.Review(r.Context(), id, status)
	if err != nil {
		writeError(w, 404, "document not found")
		return
	}
	writeJSON(w, 200, item)
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
