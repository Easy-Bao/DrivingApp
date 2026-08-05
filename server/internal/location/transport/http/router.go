package http

import (
	locationhandler "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *locationhandler.Handler }

func NewRouter(service *usecase.Service) *Router {
	return &Router{handler: locationhandler.NewHandler(service)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Route(api.V1Prefix, func(routes chi.Router) {
		routes.Route("/location", func(locationRoutes chi.Router) {
			locationRoutes.Get("/search", router.handler.Search)
			locationRoutes.Get("/nearby", router.handler.Nearby)
			locationRoutes.Get("/reverse", router.handler.Reverse)
			locationRoutes.Post("/route", router.handler.Route)
		})
	})
}
