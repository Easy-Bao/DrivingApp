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
	mux.Post(api.V1Prefix+"/telemetry/location", router.handler.UpdateDriverLocation)
	mux.Get(api.V1Prefix+"/telemetry/location/nearby", router.handler.NearbyDrivers)
	mux.Get(api.V1Prefix+"/telemetry/location/{driverID}", router.handler.GetDriverLocation)
	mux.Post(api.V1Prefix+"/telemetry/passenger/{rideID}", router.handler.UpdatePassengerLocation)
	mux.Get(api.V1Prefix+"/telemetry/passenger/{rideID}", router.handler.GetPassengerLocation)
}
