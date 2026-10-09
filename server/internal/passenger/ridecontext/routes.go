package ridecontext

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler       *Handler
	routeSecurity *middleware.RouteSecurity
}

func NewRouter(dependencies Dependencies) *Router {
	return &Router{handler: NewHandler(dependencies), routeSecurity: dependencies.RouteSecurity}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	canonicalPath := api.V1Prefix + "/passengers/me/home"
	read := router.routeSecurity.Middleware(middleware.RouteRead)
	mux.With(read).Get(canonicalPath, router.handler.GetRideContext)
	mux.With(read, middleware.Deprecation(canonicalPath)).Get(
		api.V1Prefix+"/passenger/home",
		router.handler.GetRideContext,
	)
}
