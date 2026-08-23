package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/middleware"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler  *handler.Handler
	verifier *token.Verifier
}

func NewRouter(service *usecase.Service, verifier *token.Verifier, authorizer *security.AdminAuthorizer) *Router {
	return &Router{handler: handler.NewHandler(service, verifier, authorizer), verifier: verifier}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Group(func(protected chi.Router) {
		protected.Use(middleware.RequireAuth(router.verifier))
		protected.With(middleware.RequireRole(security.RoleDriver)).Post(api.V1Prefix+"/driver/documents", router.handler.Upload)
		protected.With(middleware.RequireRole(security.RoleDriver)).Get(api.V1Prefix+"/driver/documents/status", router.handler.Status)
		protected.Patch(api.V1Prefix+"/admin/documents/{id}/review", router.handler.Review)
	})
}
