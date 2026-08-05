package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service, auth ...*security.TokenManager) *Router {
	return &Router{handler: handler.NewHandler(service, auth...)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Route(api.V1Prefix, func(routes chi.Router) {
		routes.Route("/telemetry", func(telemetryRoutes chi.Router) {
			telemetryRoutes.Post("/location", router.handler.UpdateDriverLocation)
			telemetryRoutes.Get("/location/nearby", router.handler.NearbyDrivers)
			telemetryRoutes.Get("/location/{driverID}", router.handler.GetDriverLocation)
			telemetryRoutes.Post("/passenger/{rideID}", router.handler.UpdatePassengerLocation)
			telemetryRoutes.Get("/passenger/{rideID}", router.handler.GetPassengerLocation)
		})
	})
}
