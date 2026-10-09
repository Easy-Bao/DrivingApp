package ridecontext

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *Handler }

func NewRouter(dependencies Dependencies) *Router {
	return &Router{handler: NewHandler(dependencies)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	canonicalPath := api.V1Prefix + "/passengers/me/home"
	mux.Get(canonicalPath, router.handler.GetRideContext)
	mux.With(middleware.Deprecation(canonicalPath)).Get(
		api.V1Prefix+"/passenger/home",
		router.handler.GetRideContext,
	)
}
