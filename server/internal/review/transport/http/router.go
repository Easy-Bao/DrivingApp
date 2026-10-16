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

	withAuthenticatedPolicy(read).Get(api.V1Prefix+"/drivers/{id}/reviews", router.handler.DriverReviews)
	withAuthenticatedPolicy(command, passengerOnly).Post(
		api.V1Prefix+"/drivers/{id}/reviews",
		router.handler.CreateReview,
	)
	withAuthenticatedPolicy(command, driverOnly).Post(
		api.V1Prefix+"/passengers/{id}/reviews",
		router.handler.CreatePassengerReview,
	)
}
