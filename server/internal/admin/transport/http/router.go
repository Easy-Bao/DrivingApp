package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
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
	mux.With(middleware.RequireAuth(router.verifier)).Get(api.V1Prefix+"/admin/stats", router.handler.Stats)
}
