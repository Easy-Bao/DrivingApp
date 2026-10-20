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
	authenticate := middleware.RequireAuth(router.verifier)
	passengerOnly := middleware.RequireRole(security.RolePassenger)
	driverOnly := middleware.RequireRole(security.RoleDriver)
	withAuthenticatedPolicy := func(
		policy middleware.RoutePolicy,
		guards ...func(http.Handler) http.Handler,
	) chi.Router {
		return mux.With(router.routeSecurity.Authenticated(policy, authenticate, guards...)...)
	}

	withAuthenticatedPolicy(middleware.RouteRead).Get(apiPrefix+"/bids/{sessionID}", router.handler.Session)
	mux.With(router.routeSecurity.Middleware(middleware.RouteRead)).Get(apiPrefix+"/drivers/public/summaries", router.handler.PublicDriverSummaries)
	withAuthenticatedPolicy(middleware.RouteCommand, passengerOnly).Post(apiPrefix+"/bids", router.handler.CreateSession)
	withAuthenticatedPolicy(middleware.RouteRead, passengerOnly).Get(apiPrefix+"/bids/{sessionID}/offers", router.handler.Offers)
	withAuthenticatedPolicy(middleware.RouteCommand, passengerOnly).Post(
		apiPrefix+"/bids/{sessionID}/offers/{offerID}/accept",
		router.handler.AcceptOffer,
	)
	withAuthenticatedPolicy(middleware.RouteCommand, passengerOnly).Post(apiPrefix+"/bids/{sessionID}/cancel", router.handler.CancelSession)
	withAuthenticatedPolicy(middleware.RouteRead, driverOnly).Get(apiPrefix+"/bids/active", router.handler.ActiveSessions)
	withAuthenticatedPolicy(middleware.RouteRead, passengerOnly).Get(apiPrefix+"/drivers/online", router.handler.OnlineDrivers)
	withAuthenticatedPolicy(middleware.RouteCommand, driverOnly).Post(apiPrefix+"/bids/{sessionID}/offer", router.handler.PlaceOffer)
	withAuthenticatedPolicy(middleware.RouteCommand, driverOnly).Post(apiPrefix+"/bids/{sessionID}/cancel-offer", router.handler.CancelOffer)
}
