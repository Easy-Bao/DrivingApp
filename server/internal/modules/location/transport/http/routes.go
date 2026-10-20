package http

import (
	locationapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/app"
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
	authenticate := middleware.RequireAuth(router.verifier)
	mux.With(locationPolicy).Get(api.V1Prefix+"/location/search", router.handler.Search)
	mux.With(locationPolicy).Get(api.V1Prefix+"/location/nearby", router.handler.Nearby)
	mux.With(locationPolicy).Get(api.V1Prefix+"/location/reverse", router.handler.Reverse)
	mux.With(locationPolicy, authenticate).Post(api.V1Prefix+"/location/route", router.handler.Route)
	mux.With(locationPolicy, authenticate).Post(api.V1Prefix+"/location/matrix", router.handler.Matrix)
}
