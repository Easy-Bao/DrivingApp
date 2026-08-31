package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/location/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *Handler }

func NewRouter(service *application.LocationService) *Router {
	return &Router{handler: NewHandler(service)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Get(api.V1Prefix+"/location/search", router.handler.Search)
	mux.Get(api.V1Prefix+"/location/nearby", router.handler.Nearby)
	mux.Get(api.V1Prefix+"/location/reverse", router.handler.Reverse)
	mux.Post(api.V1Prefix+"/location/route", router.handler.Route)
	mux.Post(api.V1Prefix+"/location/matrix", router.handler.Matrix)
}
