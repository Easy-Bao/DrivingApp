package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
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
	read := router.routeSecurity.Middleware(middleware.RouteRead)
	fare := router.routeSecurity.Middleware(middleware.RouteFareQuery)
	command := router.routeSecurity.Middleware(middleware.RouteCommand)
	authenticate := middleware.RequireAuth(router.verifier)
	passengerOnly := middleware.RequireRole(security.RolePassenger)
	driverOnly := middleware.RequireRole(security.RoleDriver)
	withAuthenticatedPolicy := func(
		policy func(http.Handler) http.Handler,
		guards ...func(http.Handler) http.Handler,
	) chi.Router {
		chain := []func(http.Handler) http.Handler{policy, authenticate}
		chain = append(chain, guards...)
		return mux.With(chain...)
	}

	mux.With(fare, middleware.Deprecation(apiPrefix+"/fares/estimate")).Post(
		apiPrefix+"/bids/fare",
		router.handler.Estimate,
	)
	mux.With(read).Get(apiPrefix+"/drivers/public/summaries", router.handler.PublicDriverSummaries)
	mux.With(fare).Post(apiPrefix+"/fares/estimate", router.handler.Estimate)
	mux.With(read).Get(apiPrefix+"/fares/configs", router.handler.FareConfigs)
	mux.With(read).Get(apiPrefix+"/fares/rating-config", router.handler.RatingConfig)
	mux.With(fare).Post(apiPrefix+"/fares/calculate-final", router.handler.CalculateFinal)

	withAuthenticatedPolicy(command).Post(apiPrefix+"/rides/{id}/status", router.handler.UpdateStatus)
	withAuthenticatedPolicy(command).Post(apiPrefix+"/rides/{id}/cancel", router.handler.CancelRide)
	withAuthenticatedPolicy(command).Post(apiPrefix+"/rides/{id}/emergency-stop", router.handler.EmergencyStop)
	withAuthenticatedPolicy(command).Post(apiPrefix+"/rides/{id}/reports", router.handler.CreateSafetyReport)
	withAuthenticatedPolicy(read).Get(apiPrefix+"/rides/{id}", router.handler.GetRide)
	withAuthenticatedPolicy(read).Get(apiPrefix+"/rides/{id}/counterparty", router.handler.Counterparty)
	withAuthenticatedPolicy(read).Get(apiPrefix+"/bids/{sessionID}", router.handler.Session)
	withAuthenticatedPolicy(read).Get(apiPrefix+"/drivers/{id}/reviews", router.handler.DriverReviews)

	withAuthenticatedPolicy(command, passengerOnly).Post(apiPrefix+"/rides", router.handler.CreateRide)
	withAuthenticatedPolicy(command, passengerOnly).Post(apiPrefix+"/bids", router.handler.CreateSession)
	withAuthenticatedPolicy(read, passengerOnly).Get(apiPrefix+"/bids/{sessionID}/offers", router.handler.Offers)
	withAuthenticatedPolicy(command, passengerOnly).Post(apiPrefix+"/bids/{sessionID}/offers/{offerID}/accept", router.handler.AcceptOffer)
	withAuthenticatedPolicy(command, passengerOnly).Post(apiPrefix+"/bids/{sessionID}/cancel", router.handler.CancelSession)
	withAuthenticatedPolicy(read, passengerOnly).Get(apiPrefix+"/passengers/{id}/rides", router.handler.PassengerRides)
	withAuthenticatedPolicy(read, passengerOnly).Get(
		apiPrefix+"/passengers/{id}/activity-summary",
		router.handler.PassengerActivitySummary,
	)
	withAuthenticatedPolicy(read, passengerOnly).Get(apiPrefix+"/drivers/online", router.handler.OnlineDrivers)
	withAuthenticatedPolicy(command, passengerOnly).Post(apiPrefix+"/drivers/{id}/reviews", router.handler.CreateReview)

	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/rides/{id}/accept", router.handler.AcceptRide)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/rides/{id}/arrived", router.handler.MarkArrived)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/rides/{id}/start", router.handler.StartTrip)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/rides/{id}/complete", router.handler.CompleteTrip)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/rides/{id}/no-show", router.handler.MarkPassengerNoShow)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/rides/{id}/cash-settle", router.handler.SettleCash)
	withAuthenticatedPolicy(read, driverOnly).Get(apiPrefix+"/bids/active", router.handler.ActiveSessions)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/bids/{sessionID}/offer", router.handler.PlaceOffer)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/bids/{sessionID}/cancel-offer", router.handler.CancelOffer)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/passengers/{id}/reviews", router.handler.CreatePassengerReview)
	withAuthenticatedPolicy(read, driverOnly).Get(apiPrefix+"/drivers/{id}/stats", router.handler.DriverStats)
	withAuthenticatedPolicy(read, driverOnly).Get(apiPrefix+"/drivers/{id}/earnings", router.handler.DriverEarnings)
	withAuthenticatedPolicy(read, driverOnly).Get(apiPrefix+"/drivers/{id}/trips", router.handler.DriverTrips)
}
