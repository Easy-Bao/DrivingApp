package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler    *handler.Handler
	verifier   *security.TokenManager
	authorizer *security.AdminAuthorizer
}

func NewRouter(service *usecase.Service, verifier *security.TokenManager, authorizer *security.AdminAuthorizer) *Router {
	return &Router{handler: handler.NewHandler(service), verifier: verifier, authorizer: authorizer}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.With(
		middleware.RequireAuth(router.verifier),
		middleware.RequireAdmin(router.authorizer),
	).Get(api.V1Prefix+"/admin/stats", router.handler.Stats)
}
