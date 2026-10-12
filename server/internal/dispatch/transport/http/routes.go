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

	withAuthenticatedPolicy(read).Get(apiPrefix+"/bids/{sessionID}", router.handler.Session)
	mux.With(read).Get(apiPrefix+"/drivers/public/summaries", router.handler.PublicDriverSummaries)
	withAuthenticatedPolicy(command, passengerOnly).Post(apiPrefix+"/bids", router.handler.CreateSession)
	withAuthenticatedPolicy(read, passengerOnly).Get(apiPrefix+"/bids/{sessionID}/offers", router.handler.Offers)
	withAuthenticatedPolicy(command, passengerOnly).Post(
		apiPrefix+"/bids/{sessionID}/offers/{offerID}/accept",
		router.handler.AcceptOffer,
	)
	withAuthenticatedPolicy(command, passengerOnly).Post(apiPrefix+"/bids/{sessionID}/cancel", router.handler.CancelSession)
	withAuthenticatedPolicy(read, driverOnly).Get(apiPrefix+"/bids/active", router.handler.ActiveSessions)
	withAuthenticatedPolicy(read, passengerOnly).Get(apiPrefix+"/drivers/online", router.handler.OnlineDrivers)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/bids/{sessionID}/offer", router.handler.PlaceOffer)
	withAuthenticatedPolicy(command, driverOnly).Post(apiPrefix+"/bids/{sessionID}/cancel-offer", router.handler.CancelOffer)
}
