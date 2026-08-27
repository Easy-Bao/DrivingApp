package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/usecase"
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
	mux.Group(func(protected chi.Router) {
		protected.Use(middleware.RequireAuth(router.verifier))
		protected.With(middleware.RequireRole(security.RoleDriver)).Group(func(driver chi.Router) {
			driver.Post(api.V1Prefix+"/driver/documents", router.handler.Upload)
			driver.Get(api.V1Prefix+"/driver/documents/status", router.handler.Status)
			driver.Get(api.V1Prefix+"/driver/documents/{id}/content", router.handler.DriverContent)
		})
		protected.With(middleware.RequireAdmin(router.authorizer)).Group(func(admin chi.Router) {
			admin.Get(api.V1Prefix+"/admin/documents", router.handler.ReviewQueue)
			admin.Get(api.V1Prefix+"/admin/documents/{id}/content", router.handler.AdminContent)
			admin.Patch(api.V1Prefix+"/admin/documents/{id}/review", router.handler.Review)
		})
	})
}
