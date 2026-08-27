package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler *Handler
	auth    *security.TokenManager
}

func NewRouter(
	service *usecase.LocationTrackingService,
	auth *security.TokenManager,
) *Router {
	return &Router{handler: NewHandler(service, auth), auth: auth}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Group(func(protected chi.Router) {
		protected.Use(middleware.RequireAuth(router.auth))
		protected.With(middleware.RequireRole(security.RoleDriver)).Get(api.V1Prefix+"/telemetry/location/{driverID}", router.handler.GetDriverLocation)
		protected.With(middleware.RequireRole(security.RolePassenger)).Get(api.V1Prefix+"/telemetry/rides/{rideID}/driver", router.handler.GetRideDriverLocation)
		protected.With(middleware.RequireRole(security.RoleDriver)).Post(api.V1Prefix+"/telemetry/location", router.handler.UpdateDriverLocation)
		protected.With(middleware.RequireRole(security.RoleDriver)).Delete(api.V1Prefix+"/telemetry/location", router.handler.DeleteDriverLocation)
		protected.With(middleware.RequireRole(security.RolePassenger)).Get(api.V1Prefix+"/telemetry/location/nearby", router.handler.NearbyDrivers)
		protected.With(middleware.RequireRole(security.RolePassenger)).Post(api.V1Prefix+"/telemetry/passenger/{rideID}", router.handler.UpdatePassengerLocation)
		protected.With(middleware.RequireRole(security.RoleDriver)).Get(api.V1Prefix+"/telemetry/passenger/{rideID}", router.handler.GetPassengerLocation)
	})
}
