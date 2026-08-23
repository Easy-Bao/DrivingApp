package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/middleware"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler *handler.Handler
	auth    *security.TokenManager
}

func NewRouter(service *usecase.Service, auth ...*security.TokenManager) *Router {
	var tokenManager *security.TokenManager
	if len(auth) > 0 {
		tokenManager = auth[0]
	}
	return &Router{handler: handler.NewHandler(service, tokenManager), auth: tokenManager}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Group(func(protected chi.Router) {
		protected.Use(middleware.RequireAuth(router.auth))
		protected.Get(api.V1Prefix+"/telemetry/location/{driverID}", router.handler.GetDriverLocation)
		protected.With(middleware.RequireRole(security.RoleDriver)).Post(api.V1Prefix+"/telemetry/location", router.handler.UpdateDriverLocation)
		protected.With(middleware.RequireRole(security.RoleDriver)).Delete(api.V1Prefix+"/telemetry/location", router.handler.DeleteDriverLocation)
		protected.With(middleware.RequireRole(security.RolePassenger)).Get(api.V1Prefix+"/telemetry/location/nearby", router.handler.NearbyDrivers)
		protected.With(middleware.RequireRole(security.RolePassenger)).Post(api.V1Prefix+"/telemetry/passenger/{rideID}", router.handler.UpdatePassengerLocation)
		protected.With(middleware.RequireRole(security.RoleDriver)).Get(api.V1Prefix+"/telemetry/passenger/{rideID}", router.handler.GetPassengerLocation)
	})
}
