package documents

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler       *Handler
	verifier      *security.TokenManager
	authorizer    *security.AdminAuthorizer
	routeSecurity *middleware.RouteSecurity
}

type RouterDependencies struct {
	Service       *DocumentService
	Verifier      *security.TokenManager
	Authorizer    *security.AdminAuthorizer
	RouteSecurity *middleware.RouteSecurity
}

func NewRouter(dependencies RouterDependencies) *Router {
	return &Router{
		handler:       NewHandler(dependencies.Service),
		verifier:      dependencies.Verifier,
		authorizer:    dependencies.Authorizer,
		routeSecurity: dependencies.RouteSecurity,
	}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	authenticate := middleware.RequireAuth(router.verifier)
	driverOnly := middleware.RequireRole(security.RoleDriver)
	adminOnly := middleware.RequireAdmin(router.authorizer)
	withPolicy := func(
		policy middleware.RoutePolicy,
		guards ...func(http.Handler) http.Handler,
	) chi.Router {
		chain := []func(http.Handler) http.Handler{router.routeSecurity.Middleware(policy)}
		chain = append(chain, authenticate)
		chain = append(chain, guards...)
		return mux.With(chain...)
	}

	legacyPath := api.V1Prefix + "/driver/documents"
	canonicalPath := api.V1Prefix + "/drivers/me/documents"
	withPolicy(middleware.RouteDocumentUpload, driverOnly).Post(canonicalPath, router.handler.Upload)
	withPolicy(middleware.RouteDocumentUpload, driverOnly).Post(canonicalPath+"/{type}", router.handler.UploadMultipart)
	withPolicy(middleware.RouteRead, driverOnly).Get(canonicalPath+"/status", router.handler.Status)
	withPolicy(middleware.RouteRead, driverOnly).Get(canonicalPath+"/{id}/content", router.handler.DriverContent)
	mux.With(
		router.routeSecurity.Middleware(middleware.RouteDocumentUpload),
		authenticate,
		driverOnly,
		middleware.Deprecation(canonicalPath),
	).Post(legacyPath, router.handler.Upload)
	mux.With(
		router.routeSecurity.Middleware(middleware.RouteRead),
		authenticate,
		driverOnly,
		middleware.Deprecation(canonicalPath+"/status"),
	).Get(legacyPath+"/status", router.handler.Status)
	mux.With(
		router.routeSecurity.Middleware(middleware.RouteRead),
		authenticate,
		driverOnly,
		middleware.DeprecationPrefix(legacyPath+"/", canonicalPath+"/"),
	).Get(legacyPath+"/{id}/content", router.handler.DriverContent)
	withPolicy(middleware.RouteRead, adminOnly).Get(api.V1Prefix+"/admin/documents", router.handler.ReviewQueue)
	withPolicy(middleware.RouteRead, adminOnly).Get(
		api.V1Prefix+"/admin/documents/{id}/content",
		router.handler.AdminContent,
	)
	withPolicy(middleware.RouteCommand, adminOnly).Patch(
		api.V1Prefix+"/admin/documents/{id}/review",
		router.handler.Review,
	)
}
