package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler *Handler
	auth    *security.TokenManager
}

func NewRouter(
	service *application.LocationTrackingService,
	auth *security.TokenManager,
) *Router {
	return &Router{handler: NewHandler(service, auth), auth: auth}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Group(func(protected chi.Router) {
		protected.Use(middleware.RequireAuth(router.auth))
		driverOnly := middleware.RequireRole(security.RoleDriver)
		passengerOnly := middleware.RequireRole(security.RolePassenger)
		protected.With(driverOnly).Get(api.V1Prefix+"/telemetry/location/{driverID}", router.handler.GetDriverLocation)
		protected.With(passengerOnly).Get(
			api.V1Prefix+"/telemetry/rides/{rideID}/driver",
			router.handler.GetRideDriverLocation,
		)
		protected.With(driverOnly).Post(api.V1Prefix+"/telemetry/location", router.handler.UpdateDriverLocation)
		protected.With(driverOnly).Delete(api.V1Prefix+"/telemetry/location", router.handler.DeleteDriverLocation)
		protected.With(passengerOnly).Get(api.V1Prefix+"/telemetry/location/nearby", router.handler.NearbyDrivers)
		protected.With(passengerOnly).Post(
			api.V1Prefix+"/telemetry/passenger/{rideID}",
			router.handler.UpdatePassengerLocation,
		)
		protected.With(driverOnly).Get(api.V1Prefix+"/telemetry/passenger/{rideID}", router.handler.GetPassengerLocation)
	})
}
