package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler       *Handler
	verifier      *security.TokenManager
	routeSecurity *middleware.RouteSecurity
}

func NewRouter(dependencies Dependencies) *Router {
	return &Router{
		handler:       NewHandler(dependencies),
		verifier:      dependencies.Verifier,
		routeSecurity: dependencies.RouteSecurity,
	}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	apiPrefix := api.V1Prefix
	fare := router.routeSecurity.Middleware(middleware.RouteFareQuery)
	authenticate := middleware.RequireAuth(router.verifier)
	passengerOnly := middleware.RequireRole(security.RolePassenger)
	driverOnly := middleware.RequireRole(security.RoleDriver)
	withAuthenticatedPolicy := func(
		policy middleware.RoutePolicy,
		guards ...func(http.Handler) http.Handler,
	) chi.Router {
		return mux.With(router.routeSecurity.Authenticated(policy, authenticate, guards...)...)
	}

	mux.With(fare, middleware.Deprecation(apiPrefix+"/fares/estimate")).Post(
		apiPrefix+"/bids/fare",
		router.handler.Estimate,
	)
	mux.With(fare).Post(apiPrefix+"/fares/estimate", router.handler.Estimate)
	mux.With(router.routeSecurity.Middleware(middleware.RouteRead)).Get(apiPrefix+"/fares/configs", router.handler.FareConfigs)
	mux.With(router.routeSecurity.Middleware(middleware.RouteRead)).Get(apiPrefix+"/fares/rating-config", router.handler.RatingConfig)
	driverOrAdmin := middleware.RequireRole(security.RoleDriver, "admin")
	withAuthenticatedPolicy(middleware.RouteFareQuery, driverOrAdmin).Post(
		apiPrefix+"/fares/calculate-final",
		router.handler.CalculateFinal,
	)

	withAuthenticatedPolicy(middleware.RouteCommand).Post(apiPrefix+"/rides/{id}/status", router.handler.UpdateStatus)
	withAuthenticatedPolicy(middleware.RouteCommand).Post(apiPrefix+"/rides/{id}/cancel", router.handler.CancelRide)
	withAuthenticatedPolicy(middleware.RouteCommand).Post(apiPrefix+"/rides/{id}/emergency-stop", router.handler.EmergencyStop)
	withAuthenticatedPolicy(middleware.RouteCommand).Post(apiPrefix+"/rides/{id}/reports", router.handler.CreateSafetyReport)
	withAuthenticatedPolicy(middleware.RouteRead).Get(apiPrefix+"/rides/{id}", router.handler.GetRide)
	withAuthenticatedPolicy(middleware.RouteRead).Get(apiPrefix+"/rides/{id}/counterparty", router.handler.Counterparty)

	withAuthenticatedPolicy(middleware.RouteCommand, passengerOnly).Post(apiPrefix+"/rides", router.handler.CreateRide)
	withAuthenticatedPolicy(middleware.RouteRead, passengerOnly).Get(apiPrefix+"/passengers/{id}/rides", router.handler.PassengerRides)
	withAuthenticatedPolicy(middleware.RouteRead, passengerOnly).Get(
		apiPrefix+"/passengers/{id}/activity-summary",
		router.handler.PassengerActivitySummary,
	)

	withAuthenticatedPolicy(middleware.RouteCommand, driverOnly).Post(apiPrefix+"/rides/{id}/accept", router.handler.AcceptRide)
	withAuthenticatedPolicy(middleware.RouteCommand, driverOnly).Post(apiPrefix+"/rides/{id}/arrived", router.handler.MarkArrived)
	withAuthenticatedPolicy(middleware.RouteCommand, driverOnly).Post(apiPrefix+"/rides/{id}/start", router.handler.StartTrip)
	withAuthenticatedPolicy(middleware.RouteCommand, driverOnly).Post(apiPrefix+"/rides/{id}/complete", router.handler.CompleteTrip)
	withAuthenticatedPolicy(middleware.RouteCommand, driverOnly).Post(apiPrefix+"/rides/{id}/no-show", router.handler.MarkPassengerNoShow)
	withAuthenticatedPolicy(middleware.RouteCommand, driverOnly).Post(apiPrefix+"/rides/{id}/cash-settle", router.handler.SettleCash)
	withAuthenticatedPolicy(middleware.RouteRead, driverOnly).Get(apiPrefix+"/drivers/{id}/stats", router.handler.DriverStats)
	withAuthenticatedPolicy(middleware.RouteRead, driverOnly).Get(apiPrefix+"/drivers/{id}/earnings", router.handler.DriverEarnings)
	withAuthenticatedPolicy(middleware.RouteRead, driverOnly).Get(apiPrefix+"/drivers/{id}/trips", router.handler.DriverTrips)
}
