package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/user/application"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler  *Handler
	verifier *security.TokenManager
}

func NewRouter(service *application.ProfileService, verifier *security.TokenManager) *Router {
	return &Router{handler: NewHandler(service, verifier), verifier: verifier}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Route(api.V1Prefix, func(routes chi.Router) {
		routes.Use(middleware.RequireAuth(router.verifier))
		passengerOnly := middleware.RequireRole(security.RolePassenger)
		driverOnly := middleware.RequireRole(security.RoleDriver)
		routes.Get("/users/me", router.handler.Me)
		routes.Patch("/users/me", router.handler.Update)
		routes.With(passengerOnly).Get("/passengers/{id}", router.handler.Profile)
		routes.With(passengerOnly).Put("/passengers/{id}", router.handler.ProfileUpdate)
		routes.With(passengerOnly).Get("/passengers/{id}/avatar", router.handler.Avatar)
		routes.With(passengerOnly).Post("/passengers/{id}/avatar", router.handler.AvatarUpload)
		routes.With(passengerOnly).Get("/passengers/{id}/notifications", router.handler.Notifications)
		routes.With(passengerOnly).Delete(
			"/passengers/{id}/notifications/{notificationID}",
			router.handler.DeleteNotification,
		)
		routes.With(driverOnly).Get("/drivers/{id}", router.handler.Profile)
		routes.With(driverOnly).Post("/drivers/{id}/online", router.handler.Online)
	})
}
