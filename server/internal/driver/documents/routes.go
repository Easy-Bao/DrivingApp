package documents

import (
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

type RouterDependencies struct {
	Service    *DocumentService
	Verifier   *security.TokenManager
	Authorizer *security.AdminAuthorizer
}

func NewRouter(dependencies RouterDependencies) *Router {
	return &Router{
		handler:    NewHandler(dependencies.Service),
		verifier:   dependencies.Verifier,
		authorizer: dependencies.Authorizer,
	}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Group(func(protected chi.Router) {
		protected.Use(middleware.RequireAuth(router.verifier))
		protected.With(middleware.RequireRole(security.RoleDriver)).Group(func(driver chi.Router) {
			legacyPath := api.V1Prefix + "/driver/documents"
			canonicalPath := api.V1Prefix + "/drivers/me/documents"
			driver.Post(canonicalPath, router.handler.Upload)
			driver.Get(canonicalPath+"/status", router.handler.Status)
			driver.Get(canonicalPath+"/{id}/content", router.handler.DriverContent)
			driver.With(middleware.Deprecation(canonicalPath)).Post(legacyPath, router.handler.Upload)
			driver.With(middleware.Deprecation(canonicalPath+"/status")).Get(
				legacyPath+"/status",
				router.handler.Status,
			)
			driver.With(middleware.DeprecationPrefix(legacyPath+"/", canonicalPath+"/")).Get(
				legacyPath+"/{id}/content",
				router.handler.DriverContent,
			)
		})
		protected.With(middleware.RequireAdmin(router.authorizer)).Group(func(admin chi.Router) {
			admin.Get(api.V1Prefix+"/admin/documents", router.handler.ReviewQueue)
			admin.Get(api.V1Prefix+"/admin/documents/{id}/content", router.handler.AdminContent)
			admin.Patch(api.V1Prefix+"/admin/documents/{id}/review", router.handler.Review)
		})
	})
}
