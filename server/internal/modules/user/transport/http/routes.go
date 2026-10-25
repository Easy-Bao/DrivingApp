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
	mux.Route(api.V1Prefix, func(routes chi.Router) {
		authenticate := middleware.RequireAuth(router.verifier)
		passengerOnly := middleware.RequireRole(security.RolePassenger)
		driverOnly := middleware.RequireRole(security.RoleDriver)
		withPolicy := func(policy middleware.RoutePolicy, guards ...func(http.Handler) http.Handler) chi.Router {
			return routes.With(router.routeSecurity.Authenticated(policy, authenticate, guards...)...)
		}
		withPolicy(middleware.RouteRead).Get("/users/me", router.handler.Me)
		withPolicy(middleware.RouteCommand).Patch("/users/me", router.handler.Update)
		withPolicy(middleware.RouteRead, passengerOnly).Get("/passengers/{id}", router.handler.Profile)
		withPolicy(middleware.RouteCommand, passengerOnly).Put("/passengers/{id}", router.handler.ProfileUpdate)
		withPolicy(middleware.RouteRead, passengerOnly).Get("/passengers/{id}/avatar", router.handler.Avatar)
		withPolicy(middleware.RouteCommand, passengerOnly).Post("/passengers/{id}/avatar", router.handler.AvatarUpload)
		withPolicy(middleware.RouteRead, passengerOnly).Get("/passengers/{id}/notifications", router.handler.Notifications)
		withPolicy(middleware.RouteCommand, passengerOnly).Post("/passengers/{id}/notifications/read-all", router.handler.MarkAllNotificationsRead)
		withPolicy(middleware.RouteCommand, passengerOnly).Delete(
			"/passengers/{id}/notifications/{notificationID}",
			router.handler.DeleteNotification,
		)
		withPolicy(middleware.RouteRead, driverOnly).Get("/drivers/{id}", router.handler.Profile)
		withPolicy(middleware.RouteOnlinePresence, driverOnly).Post("/drivers/{id}/online", router.handler.Online)
	})
}
