package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/go-chi/chi/v5"
)

type PassengerContextRouter struct {
	handler       *PassengerContextHandler
	routeSecurity *middleware.RouteSecurity
}

func NewPassengerContextRouter(dependencies PassengerContextDependencies) *PassengerContextRouter {
	return &PassengerContextRouter{handler: NewPassengerContextHandler(dependencies), routeSecurity: dependencies.RouteSecurity}
}

func (router *PassengerContextRouter) RegisterRoutes(mux chi.Router) {
	canonicalPath := api.V1Prefix + "/passengers/me/home"
	read := router.routeSecurity.Middleware(middleware.RouteRead)
	mux.With(read).Get(canonicalPath, router.handler.GetRideContext)
	mux.With(read, middleware.Deprecation(canonicalPath)).Get(
		api.V1Prefix+"/passenger/home",
		router.handler.GetRideContext,
	)
}
