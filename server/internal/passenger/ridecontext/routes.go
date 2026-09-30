package ridecontext

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *Handler }

func NewRouter(dependencies Dependencies) *Router {
	return &Router{handler: NewHandler(dependencies)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Get(api.V1Prefix+"/passenger/home", router.handler.GetRideContext)
}
