package http

import (
	locationapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler       *Handler
	verifier      *security.TokenManager
	routeSecurity *middleware.RouteSecurity
}

func NewRouter(
	service *locationapp.Service,
	verifier *security.TokenManager,
	routeSecurity ...*middleware.RouteSecurity,
) *Router {
	var security *middleware.RouteSecurity
	if len(routeSecurity) > 0 {
		security = routeSecurity[0]
	}
	return &Router{handler: NewHandler(service), verifier: verifier, routeSecurity: security}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	locationPolicy := router.routeSecurity.Middleware(middleware.RouteLocationQuery)
	optionalAuth := middleware.OptionalAuth(router.verifier)
	authenticate := middleware.RequireAuth(router.verifier)

	// Read-only place lookups support rate-limited guest browsing while still
	// rejecting malformed or expired tokens when an Authorization header is sent.
	mux.With(locationPolicy, optionalAuth).Group(func(lookup chi.Router) {
		lookup.Get(api.V1Prefix+"/location/search", router.handler.Search)
		lookup.Get(api.V1Prefix+"/location/nearby", router.handler.Nearby)
		lookup.Get(api.V1Prefix+"/location/reverse", router.handler.Reverse)
	})

	// Routing and travel-matrix endpoints remain strictly authenticated.
	mux.With(locationPolicy, authenticate).Group(func(protected chi.Router) {
		protected.Post(api.V1Prefix+"/location/route", router.handler.Route)
		protected.Post(api.V1Prefix+"/location/matrix", router.handler.Matrix)
	})
}
