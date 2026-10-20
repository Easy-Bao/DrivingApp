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
	authenticate := middleware.RequireAuth(router.verifier)
	passengerOnly := middleware.RequireRole(security.RolePassenger)
	driverOnly := middleware.RequireRole(security.RoleDriver)
	withAuthenticatedPolicy := func(
		policy middleware.RoutePolicy,
		guards ...func(http.Handler) http.Handler,
	) chi.Router {
		return mux.With(router.routeSecurity.Authenticated(policy, authenticate, guards...)...)
	}

	withAuthenticatedPolicy(middleware.RouteRead).Get(api.V1Prefix+"/drivers/{id}/reviews", router.handler.DriverReviews)
	withAuthenticatedPolicy(middleware.RouteCommand, passengerOnly).Post(
		api.V1Prefix+"/drivers/{id}/reviews",
		router.handler.CreateReview,
	)
	withAuthenticatedPolicy(middleware.RouteCommand, driverOnly).Post(
		api.V1Prefix+"/passengers/{id}/reviews",
		router.handler.CreatePassengerReview,
	)
}
