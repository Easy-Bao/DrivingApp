package tracking

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler       *Handler
	auth          *security.TokenManager
	routeSecurity *middleware.RouteSecurity
}

func NewRouter(dependencies Dependencies) *Router {
	return &Router{
		handler:       NewHandler(dependencies),
		auth:          dependencies.Auth,
		routeSecurity: dependencies.RouteSecurity,
	}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.With(
		router.routeSecurity.Middleware(middleware.RouteTelemetry),
		middleware.RequireAuth(router.auth),
	).Group(func(protected chi.Router) {
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
