package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/admin/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler    *Handler
	verifier   *security.TokenManager
	authorizer *security.AdminAuthorizer
}

func NewRouter(service *application.DashboardStatsService, verifier *security.TokenManager, authorizer *security.AdminAuthorizer) *Router {
	return &Router{handler: NewHandler(service), verifier: verifier, authorizer: authorizer}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.With(
		middleware.RequireAuth(router.verifier),
		middleware.RequireAdmin(router.authorizer),
	).Get(api.V1Prefix+"/admin/stats", router.handler.Stats)
}
